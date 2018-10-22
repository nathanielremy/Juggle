// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

//Listen for new messages
exports.messageAdded = functions.database.ref('/messages/{messageId}')
  .onCreate((snapshot, context) => {

    var messageId = context.params.messageId;

    return admin.database().ref('/messages/' + messageId).once('value', (snapshot) => {

      var message = snapshot.val();
      var toId = message.toId;
      var fromId = message.fromId;
      var taskId = message.taskId;
      var taskOwnerId = message.taskOwnerId;

      return admin.database().ref('/users/' + toId).once('value', (snapshot) => {

        var messageReceiver = snapshot.val()

        return admin.database().ref('/users/' + fromId).once('value', (snapshot) => {

          var messageSender = snapshot.val()

          var message = {
            notification: {
              title: 'New Message',
              body: messageSender.fullName + ' sent you a new message.'
            },
            data: {
              type: 'message',
              taskOwnerId: taskOwnerId,
              fromId: fromId,
              taskId: taskId
            },
            token: messageReceiver.fcmToken
          };

          admin.messaging().send(message)
            .then((response) => {
              // Response is a message ID string.
              console.log('Successfully sent message:', response);
              return
            })
            .catch((error) => {
              console.log('Error sending message:', error);
              return
            });
        })
      })
    })
});
