const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const sendGrid = require("@sendgrid/mail");
const twilio = require("twilio");

admin.initializeApp();

const firestore = admin.firestore();

const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY || "";
const EMAIL_FROM = process.env.EMAIL_FROM || "alerts@lostly.app";
const TWILIO_SID = process.env.TWILIO_ACCOUNT_SID || "";
const TWILIO_TOKEN = process.env.TWILIO_AUTH_TOKEN || "";
const TWILIO_PHONE = process.env.TWILIO_PHONE_NUMBER || "";

if (SENDGRID_API_KEY) {
  sendGrid.setApiKey(SENDGRID_API_KEY);
}

function shouldSendChannel(notificationType, preferences, channel) {
  if (!preferences) return false;
  if (channel === "push" && preferences.pushEnabled === false) return false;
  if (channel === "email" && preferences.emailAlertsEnabled !== true) return false;
  if (channel === "sms" && preferences.smsAlertsEnabled !== true) return false;

  if (notificationType === "match" && preferences.matchAlertsEnabled === false) {
    return false;
  }
  if (notificationType === "claim" && preferences.claimAlertsEnabled === false) {
    return false;
  }
  if (notificationType === "reminder" && preferences.reminderAlertsEnabled === false) {
    return false;
  }
  return true;
}

async function sendPush(user, notification) {
  if (!user?.fcmToken) return;
  await admin.messaging().send({
    token: user.fcmToken,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: {
      type: notification.type || "status",
      referenceId: notification.referenceId || "",
      ...Object.fromEntries(
        Object.entries(notification.data || {}).map(([key, value]) => [
          key,
          String(value ?? ""),
        ]),
      ),
    },
    android: {
      priority: "high",
      notification: {
        channelId: "lostly_alerts",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  });
}

async function sendEmail(preferences, notification) {
  if (!SENDGRID_API_KEY || !preferences?.emailAddress) {
    return;
  }

  await sendGrid.send({
    to: preferences.emailAddress,
    from: EMAIL_FROM,
    subject: `[Lostly] ${notification.title}`,
    text: `${notification.body}\n\nОткройте Lostly, чтобы посмотреть детали.`,
    html: `
      <div style="font-family:Arial,sans-serif;padding:24px;background:#f6fbfb;color:#17324d">
        <h2 style="margin:0 0 12px">Lostly</h2>
        <h3 style="margin:0 0 8px">${notification.title}</h3>
        <p style="margin:0 0 12px">${notification.body}</p>
        <p style="margin:0;color:#5f7288">Откройте приложение, чтобы увидеть полную карточку совпадения, чата или передачи вещи.</p>
      </div>
    `,
  });
}

async function sendSms(preferences, notification) {
  if (!TWILIO_SID || !TWILIO_TOKEN || !TWILIO_PHONE || !preferences?.smsNumber) {
    return;
  }

  const client = twilio(TWILIO_SID, TWILIO_TOKEN);
  await client.messages.create({
    from: TWILIO_PHONE,
    to: preferences.smsNumber,
    body: `Lostly: ${notification.title}. ${notification.body}`,
  });
}

exports.fanOutNotificationAlerts = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const notification = event.data?.data();
    if (!notification?.userId) {
      return;
    }

    const [userSnap, preferencesSnap] = await Promise.all([
      firestore.collection("users").doc(notification.userId).get(),
      firestore.collection("user_preferences").doc(notification.userId).get(),
    ]);

    const user = userSnap.exists ? userSnap.data() : null;
    const preferences = preferencesSnap.exists ? preferencesSnap.data() : null;

    try {
      if (shouldSendChannel(notification.type, preferences, "push")) {
        await sendPush(user, notification);
      }
      if (shouldSendChannel(notification.type, preferences, "email")) {
        await sendEmail(preferences, notification);
      }
      if (shouldSendChannel(notification.type, preferences, "sms")) {
        await sendSms(preferences, notification);
      }
    } catch (error) {
      logger.error("Notification fan-out failed", error);
    }
  },
);

exports.sendPickupReminders = onSchedule(
  {
    schedule: "every 30 minutes",
    timeZone: "Asia/Almaty",
  },
  async () => {
    const now = new Date();
    const soon = new Date(now.getTime() + 90 * 60 * 1000);

    const snapshot = await firestore
      .collection("pickup_schedules")
      .where("scheduledAt", ">=", now)
      .where("scheduledAt", "<=", soon)
      .get();

    const batch = firestore.batch();
    const jobs = [];

    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      if (!["proposed", "confirmed"].includes(data.status)) {
        return;
      }

      const lastReminderAt = data.lastReminderAt?.toDate?.();
      if (lastReminderAt && now - lastReminderAt < 4 * 60 * 60 * 1000) {
        return;
      }

      [data.ownerId, data.claimantId].forEach((userId) => {
        if (!userId) return;
        jobs.push(
          firestore.collection("notifications").add({
            userId,
            title: "Скоро встреча для возврата вещи",
            body: `Передача назначена на ${data.locationName}. Проверьте время и место встречи в Lostly.`,
            type: "reminder",
            referenceId: data.postId || "",
            isRead: false,
            data: {
              postId: data.postId || "",
              claimId: data.claimId || "",
              scheduleId: doc.id,
            },
            createdAt: admin.firestore.Timestamp.now(),
          }),
        );
      });

      batch.set(
        doc.ref,
        { lastReminderAt: admin.firestore.Timestamp.now() },
        { merge: true },
      );
    });

    await Promise.all(jobs);
    await batch.commit();
  },
);
