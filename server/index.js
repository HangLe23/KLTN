const express = require("express");
const cors = require("cors");
const { createServer } = require("http");
const { Server } = require("socket.io");
const multer = require("multer");
const path = require("path"); 
const fs = require('fs');

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
const upload = multer({ storage: storage });
app.use(cors());
app.get('/downloads', (req, res) => {
  const fileName = req.query.name;
  console.log(fileName);
  const filePath = path.join(__dirname, './uploads', fileName);

    // Kiểm tra xem file có tồn tại không
    if (fs.existsSync(filePath)) {
      // Sử dụng res.download() để gửi file về client
      res.download(filePath, fileName, (err) => {
          if (err) {
              // Xử lý lỗi nếu có
              console.error('Error downloading file:', err);
              res.status(500).send('Internal Server Error');
          }
      });
  } else {
      // Trả về lỗi nếu file không tồn tại
      res.status(404).send('File not found');
  }
    
});
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

httpServer.listen(port, '0.0.0.0', () => {
  console.log(`Server running at http://localhost${port}`);
});