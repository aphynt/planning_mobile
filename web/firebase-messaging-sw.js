// web/firebase-messaging-sw.js

importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCMXeWsRioZCqhfP4FoKt6W4RxpXU0zGf0",
  authDomain: "planner-app-140d2.firebaseapp.com",
  projectId: "planner-app-140d2",
  storageBucket: "planner-app-140d2.firebasestorage.app",
  messagingSenderId: "722794013211",
  appId: "1:722794013211:web:bd123a33c63203a89c4ebe",
});

// Ambil messaging instance
const messaging = firebase.messaging();
