import java.text.SimpleDateFormat;
import java.util.Calendar;
import processing.serial.*;

Serial myPort;  // 串口对象
float pressure;
Table pressureData;
int numRows;
String fileName = "pressure_data.csv";
int maxRows = 10;  // 我們只繪製最新的10筆資料
boolean isPressureHigh = false;  // 判斷壓力是否超過1000

void setup() {
  size(800, 600);

  // 初始化或讀取現有的 CSV 檔案
  pressureData = loadTable(fileName, "header");

  if (pressureData == null) {
    // 如果檔案不存在，則創建新的 Table 並添加標題
    pressureData = new Table();
    pressureData.addColumn("Time");
    pressureData.addColumn("Left");
  }

  numRows = pressureData.getRowCount();
  println("Number of rows in CSV: " + numRows);

  if (Serial.list().length > 0) {
    String portName = Serial.list()[0];  // 根據你的 Arduino 串口选择合適的索引
    myPort = new Serial(this, portName, 9600);
  } else {
    println("No serial ports available.");
  }
}

void draw() {
  if (myPort != null && myPort.available() > 0) {
    String inString = myPort.readStringUntil('\n');
    if (inString != null) {
      inString = trim(inString);  // 移除多余的空白字符
      if (inString.matches("\\d+")) {
        pressure = float(inString);  // 将接收到的数据转换为浮点型

        // 根据压力值来改变圆的颜色
        background(255);  // 清除屏幕背景
        if (pressure > 1000) {
          fill(0);  // 压力超过1000时，圆变成红色
          isPressureHigh = true;
        } else {
          fill(255, 0, 0);  // 压力低于1000时，圆变成黑色
          isPressureHigh = false;
        }

        // 绘制圆
        ellipse(width / 2, height / 2, 200, 200);  // 在屏幕中心绘制一个200x200的圆

        // 显示当前压力值
        fill(0);
        textSize(32);
        text("Pressure: " + nf(pressure, 1, 2), 50, 50);

        // 获取当前时间，格式 yyyy/MM/dd HH:mm:ss
        String timeStamp = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss").format(Calendar.getInstance().getTime());

        // 添加新的一行数据到 Table
        TableRow newRow = pressureData.addRow();
        newRow.setString("Time", timeStamp);
        newRow.setFloat("Pressure (hPa)", pressure);

        // 保存更新的 Table 到 CSV 文件
        saveTable(pressureData, fileName);

        // 重新读取 CSV 文件数据，确保读取的数据是最新的
        pressureData = loadTable(fileName, "header");
        numRows = pressureData.getRowCount();

        // 如果压力过高，显示警告信息
        if (isPressureHigh) {
          fill(0);  // 设置警告字体颜色为红色
          textSize(48);
          text("Left step off", 200, 550);
        }
        else 
          fill(255, 0, 0);  // 设置警告字体颜色为红色
          textSize(48);
          text("Left step on", 200, 550);
        

        delay(300);  // 延迟以便可以读取新的数据
      }
    }
  }
}


void keyPressed() {
  // 當按下Q時退出程式
  if (key == 'Q' || key == 'q') {
    exit();  // 退出程式
  }
}
