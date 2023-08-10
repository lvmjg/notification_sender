const functions = require("firebase-functions");

const admin = require("firebase-admin");
admin.initializeApp();

// // Create and deploy your first functions
// // https://firebase.google.com/docs/functions/get-started
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

//
exports.notifier = functions.database.instance('notificationsender-43b71-default-rtdb').ref('/messages/{topic}/{key}')
.onCreate((snapshot, context) => {
    const topic = context.params.topic;
    subtopics = topic.split('_');
    topicPath = '';

    subtopics.forEach(function(element){
        topicPath += element;

        console.log('For loop: ' + topicPath);

        sendMessage(topicPath, snapshot.val());

        topicPath += '_';
    });
 });

function sendMessage(topicPath, original){
       console.log("Function sendNotification: ", topicPath);

       const ref = admin.database().ref('topics')
               ref.orderByValue()
               .equalTo(topicPath)
               .on('value', (snapshot) => {
                   snapshot.forEach((data) => {
                            topicFormatted = topicPath.replaceAll('%', ' ');
                            topicFormatted = topicFormatted.replaceAll('_', ' > ');

                            const message = {
                                        data: {
                                           topic: topicFormatted,
                                           message: original['message'],
                                           date: original['date']
                                        },
                                        notification:{
                                            title: topicFormatted,
                                            body: original['message']
                                        },
                                        topic: topicPath
                            };

                            console.log('Database Key ' + data.key + ' value ' + data.val(), message);

                            admin.messaging().send(message)
                                          .then((response) => {
                                            console.log("Successfully sent message:", message);
                                            ref.off();
                                          })
                                          .catch((error) => {
                                            console.log("Error sending message:", error);
                                            ref.off();
                                          });
                   });
        });

 }
