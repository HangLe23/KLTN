const express = require("express");
const cors = require("cors");
const { createServer } = require("http");
const { Server } = require("socket.io");
const multer = require("multer");
const path = require("path");
const bodyParser = require('body-parser');
const mqtt = require('mqtt');
const fs = require('fs');
const { Console } = require("console");
const { spawn } = require('child_process');

// Các khai báo khác...
const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer);
const port = 8000;
const uploadDirectory = './uploads';
const brokerUrl = 'mqtt://192.168.120.88:1883';
const options = {
  username: 'andinh',
  password: '20520370'
};
const mqttClient = mqtt.connect(brokerUrl, options);

// xử lý tệp tải lên
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDirectory);
  },
  filename: function (req, file, cb) {
    cb(null, file.originalname);
  }
});
const upload = multer({ storage: storage });

// đảm bảo thư mục lưu trữ tồn tại
if (!fs.existsSync(uploadDirectory)) {
    fs.mkdirSync(uploadDirectory);
}

app.use(cors());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// trang chủ web
app.use(express.static(path.join(__dirname, 'public-flutter')));
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "public-flutter/index.html"));
});

// Route để lấy danh sách các tệp đã upload
app.get('/getUpdateFiles', (req, res) => {
    const updateFiles = fs.readdirSync(uploadDirectory);
    res.json({ files: updateFiles });
});

// route xử lý tệp tải lên
app.post('/uploads', upload.single('file'), (req, res) => {
  io.emit('fileUploaded', req.file.originalname);
  console.log('File upload!')
  res.send('File uploaded!');
});

app.post('/downloads', (req, res) => {
  const file = req.body.file;
  console.log(file);
  const nodeId = req.body.nodeId; // Node ID

  // Validate request body
  if (!file || typeof file !== 'string' || !nodeId || typeof nodeId !== 'string') {
    return res.status(400).json({ error: 'Invalid request' });
  }
  const topic = 'server/download_request';
  const parts = file.split('-');
  const service = parts[0];
  const rx = parts[1];
  const message = `${nodeId}_${service}-${rx}`;
  //const message = `${nodeId}_${file}`
  const client = mqtt.connect(brokerUrl, options);
  client.publish(topic, message, (err) => {
    if (err) {
      console.error('Error publishing message:', err);
      return res.status(500).json({ error: 'Failed to send download request' });
    }
    // Publish thành công
    res.status(200).json({ message: 'Download request sent successfully' });
  });
});


  
// add node mới
app.post("/addNode", (req, res) => {
  const { id, cpu, gpu, ram, services, sdr } = req.body;

  const client = mqtt.connect(brokerUrl, options);

  client.on('connect', () => {
    client.publish('server/info_request', 'reqinfo', (err) => {
      if (err) {
        console.error('Error publishing message:', err);
        res.status(500).send('Error adding node');
        return;
      }
      client.subscribe('device/info', (err) => {
        if (err) {
          console.error('Error subscribing to device/info:', err);
          res.status(500).send('Error adding node');
        }
      });
    });
  });

  client.on('message', (topic, message) => {
    if (topic === 'device/info') {
      const infoMessage = message.toString();
      const parts = infoMessage.split('_');

      const id = parts[0];
      const cpu = parts[1];
      const gpu = parts[2];
      const ram = parts[3];
      const services = parts[4];
      const sdr = parts[5];

      io.emit('infoMessage', { id, cpu, gpu, ram, services, sdr });
    }
  });

  client.on('error', (err) => {
    console.error('Error connecting to MQTT broker:', err);
    res.status(500).send('Error adding node');
  });
});

// New route for triggering the "all" message
app.post('/downloadAll', (req, res) => {
  try {
    const { selectedFiles } = req.body;
    console.log('Selected files:', selectedFiles);

    // Kết nối tới MQTT broker
    const client = mqtt.connect(brokerUrl, options);

    // Chuẩn bị và gửi message cho từng file qua kênh server/download_request
    selectedFiles.forEach((file) => {
        const topic = 'server/download_request';
        const message = `all_${file}`;
        console.log(file); 

        client.publish(topic, message, (err) => {
            if (err) {
                console.error(`Error publishing message for file ${file}:`, err);
                return res.status(500).json({ error: `Failed to send download request for file ${file}` });
            }
            console.log(`Download request sent for file ${file}`);
        });
    });

    // Publish thành công
    res.status(200).json({ message: 'Download requests sent successfully' });
} catch (err) {
    console.error('Error handling download all request:', err);
    res.status(500).json({ error: 'Internal server error' });
}
});

// cập nhật tiến trình tải xuống trên kênh device/download
mqttClient.on('connect', () => {
  mqttClient.subscribe('device/download_progress', (err) => {
    if (err) {
      console.error('Error subscribing to device/download_progress:', err);
    }
  });
  mqttClient.subscribe('device/update_progress', (err) => {
    if (err) {
      console.error('Error subscribing to device/update_progress:', err);
    }
  });
});

mqttClient.on('message', (topic, message) => {
  if (topic === 'device/download_progress') {
    const progressMessage = message.toString();
    const part = progressMessage.split('_');
    const id = part[0];
    const progress = part[2];
    io.emit('downloadProgress', progressMessage);
  } else if (topic === 'device/update_progress') {
    const progressMessage = message.toString();
    const part = progressMessage.split('_');
    const id = part[0];
    const progress = part[2];
    io.emit('updateProgress', progressMessage);
  }
});

mqttClient.on('error', (err) => {
  console.error('Error with MQTT client:', err);
});

io.on("connection", (client) => {
  console.log(`New client connected`);
  client.on('upload', upload.single('file'), (file) => {
    console.log(`File received: ${file.originalname}`);
    io.emit('file', file.originalname);
  });
  client.on('disconnect', () => console.log(`Client disconnected`));
});

httpServer.listen(port, '0.0.0.0', () => {
  console.log(`Server running at http://172.31.0.131:${port}`);
});

app.use(express.static(__dirname));
