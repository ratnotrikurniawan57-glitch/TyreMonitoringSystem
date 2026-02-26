const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// Inisialisasi Admin SDK (Kunci Aman di Server Google)
admin.initializeApp();

// TRIGGER: Begitu ada laporan baru di Firestore folder 'inspections'
exports.kirimNotifTemuan = onDocumentCreated("inspections/{docId}", (event) => {
    const data = event.data.data();

    // FILTER SAKTI: Cuma kirim kalau statusnya 'temuan' (Blink Kuning)
    if (data.condition === "temuan") {
        const payload = {
            notification: {
                title: `🚨 TEMUAN UNIT: ${data.unit_code.toUpperCase()}`,
                body: `Lokasi: ${data.lokasi}. Masalah: ${data.finding_desc || "Segera cek unit!"}`,
            },
            // Kirim ke semua HP yang sudah 'subscribe' di main.dart tadi
            topic: "temuan_unit", 
        };

        // Eksekusi kirim via jalur resmi Firebase
        return admin.messaging().send(payload)
            .then(() => {
                console.log(`✅ Notif Temuan ${data.unit_code} Berhasil Disebar!`);
            })
            .catch((error) => {
                console.error("❌ Gagal Kirim Notif:", error);
            });
    }

    // Kalau statusnya 'aman', fungsi ini diem aja (Hemat kuota & batre)
    console.log(`ℹ️ Unit ${data.unit_code} Aman. Tidak kirim notif.`);
    return null;
});