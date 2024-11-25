const { SerialPort } = require('serialport');
const { ReadlineParser } = require('@serialport/parser-readline');

const port = new SerialPort({ path: 'COM3', baudRate: 9600 });
const parser = port.pipe(new ReadlineParser({ delimiter: '\n' }));

let lastData = null;
port.on('data', (data) => {
    console.log('Raw data:', data.toString('utf8')); // 明確以 UTF-8 解碼
});


// 確保數據以 UTF-8 編碼處理
parser.on('data', (data) => {
    try {
        const rawData = data.toString('utf8').trim(); // 將數據轉為 UTF-8 並移除多餘空格
        console.log('Raw data:', rawData);

        const parsedData = rawData.split(',');
        if (parsedData.length === 2) {
            lastData = parsedData.map(Number); // 將數據轉為數字
            console.log('Parsed data:', lastData);
        } else {
            console.error('Invalid data format:', rawData);
        }
    } catch (err) {
        console.error('Error parsing data:', err.message);
    }
});

parser.on('error', (err) => {
    console.error('Serial Port Error:', err.message);
});

// 設定伺服器
const express = require('express');
const app = express();
const cors = require('cors');
app.use(cors());

app.get('/data', (req, res) => {
    console.log('Last Data Request:', lastData);
    if (lastData) {
        res.json({ pressure: lastData });
    } else {
        res.status(400).json({ error: 'No data available' });
    }
});

app.listen(3001, () => {
    console.log('Server is running on http://localhost:3001');
});
