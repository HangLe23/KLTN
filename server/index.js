const express = require("express");
const cors = require("cors");
const { createServer } = require("http");
const { Server } = require("socket.io");
const multer = require("multer");
const path = require("path"); // Thêm dòng này

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer);
const port = 8080;

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/'); // Thư mục lưu trữ tệp tải lên
  },
  filename: function (req, file, cb) {
    cb(null, file.originalname);
  }
});
// app.get('/', (req, res) => {
//   //const updateFiles = fs.readdirSync(uploadDirectory);
//   res.sendFile(path.join(__dirname, 'index.html'));
// });
const upload = multer({ storage: storage });
app.use(cors());
app.post('/uploads', upload.single('file'), (req, res) => {
  // Xử lý tệp đã được tải lên
  res.send('File uploaded!');
});

io.on("connection", (client) => {
  console.log(`New client connected`);
  client.on('upload', upload.single('file'), (file) => {
    console.log(`File received: ${file.originalname}`);
    io.emit('file', file.originalname); // Broadcast the file name to all clients
  });
  client.on('disconnect', () => console.log(`Client disconnected`));
});

httpServer.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
