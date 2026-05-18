const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

async function sendNotificationToToken(token, title, body, data) {
  if (!token) {
    console.log('Missing FCM token, skipping notification');
    return null;
  }

  const message = {
    token,
    notification: { title, body },
    data: data || {},
    android: {
      priority: 'high',
      notification: {
        channelId: 'high_importance_channel',
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: { sound: 'default', badge: 1 },
      },
    },
  };

  return admin.messaging().send(message);
}

exports.onVisitRequestCreated = functions.firestore
  .document('visit_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const request = snap.data();
    if (!request) return null;

    const ownerId = request.ownerId;
    const ownerDoc = await admin.firestore().collection('users').doc(ownerId).get();
    const ownerToken = ownerDoc.exists ? ownerDoc.data().fcmToken : null;

    await sendNotificationToToken(
      ownerToken,
      'New Visit Request',
      `${request.tenantName || 'A tenant'} requested to visit ${request.listingTitle || 'your listing'}`,
      {
        type: 'property_request',
        targetRole: 'landlord',
        requestId: context.params.requestId,
        listingId: request.listingId || '',
        propertyTitle: request.listingTitle || '',
        tenantName: request.tenantName || '',
      }
    );

    return null;
  });

exports.onVisitRequestUpdated = functions.firestore
  .document('visit_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return null;
    if (before.status === after.status) return null;
    if (after.status !== 'accepted' && after.status !== 'rejected') return null;

    const tenantDoc = await admin.firestore().collection('users').doc(after.tenantId).get();
    const tenantToken = tenantDoc.exists ? tenantDoc.data().fcmToken : null;

    await sendNotificationToToken(
      tenantToken,
      after.status === 'accepted' ? 'Request Accepted' : 'Request Rejected',
      after.status === 'accepted'
        ? `Your visit request for ${after.listingTitle || 'this listing'} has been accepted`
        : `Your visit request for ${after.listingTitle || 'this listing'} was rejected`,
      {
        type: 'request_response',
        targetRole: 'tenant',
        status: after.status,
        requestId: context.params.requestId,
        listingId: after.listingId || '',
        propertyTitle: after.listingTitle || '',
      }
    );

    return null;
  });
