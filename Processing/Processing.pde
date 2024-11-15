import java.text.SimpleDateFormat;
import java.util.Calendar;
import processing.serial.*;

Serial myPort;  // 串口对象
float leftPressure;  // Left 压力数据
float rightPressure;  // Right 压力数据
Table pressureData;
int numRows;
String fileName = "pressure_data.csv";
int maxRows = 10;  // 我们只绘制最新的10笔数据
boolean isPressureHighLeft = false;  // 判断左侧压力是否超过1000
boolean isPressureHighRight = false;  // 判断右侧压力是否超过1000

void setup() {
  size(800, 600);

  // 初始化或读取现有的 CSV 文件
  pressureData = loadTable(fileName, "header");
  if (pressureData == null || !hasColumn(pressureData, "Left") || !hasColumn(pressureData, "Right")) {
    // 如果文件不存在或缺少 "Left" 或 "Right" 列，则创建新的 Table 并添加标题
    println("CSV file not found, creating a new one.");
    pressureData = new Table();
    pressureData.addColumn("Time");
    pressureData.addColumn("Left");
    pressureData.addColumn("Right");
  } else {
    println("CSV file loaded successfully.");
  }

  numRows = pressureData.getRowCount();
  println("Number of rows in CSV: " + numRows);

  if (Serial.list().length > 0) {
    String portName = Serial.list()[0];  // 根据你的 Arduino 串口选择合适的索引
    myPort = new Serial(this, portName, 9600);
  } else {
    println("No serial ports available.");
  }
}

void draw() {
  if (myPort != null && myPort.available() > 0) {
    String inString = myPort.readStringUntil('\n');
    println("Received data: " + inString);  // 调试输出

    if (inString != null) {
      inString = trim(inString);  // 移除多余的空白字符
      String[] pressures = split(inString, ',');  // 假设 Arduino 发来的数据格式是 "leftPressure,rightPressure"
      println("Split data: " + pressures[0] + ", " + pressures[1]);  // 调试输出

      if (pressures.length == 2) {
        leftPressure = float(pressures[0]);  // 将接收到的左侧压力数据转换为浮动型
        rightPressure = float(pressures[1]);  // 将接收到的右侧压力数据转换为浮动型

        // 根据压力值来改变圆的颜色
        background(255);  // 清除屏幕背景

        // 控制左侧压力的圆
        if (leftPressure > 1000) {
          fill(0);  // 左侧压力超过1000时，圆变成红色
          isPressureHighLeft = true;
        } else {
          fill(255, 0, 0);  // 左侧压力低于1000时，圆变成黑色
          isPressureHighLeft = false;
        }
        ellipse(width / 3, height / 2, 200, 200);  // 绘制左侧压力的圆

        // 控制右侧压力的圆
        if (rightPressure > 1000) {
          fill(0);  // 右侧压力超过1000时，圆变成绿色
          isPressureHighRight = true;
        } else {
          fill(0, 0, 255);  // 右侧压力低于1000时，圆变成蓝色
          isPressureHighRight = false;
        }
        ellipse(2 * width / 3, height / 2, 200, 200);  // 绘制右侧压力的圆

        // 显示当前压力值
        fill(0);
        textSize(32);
        text("Left Pressure: " + nf(leftPressure, 1, 2), 50, 50);
        text("Right Pressure: " + nf(rightPressure, 1, 2), 50, 100);

        // 获取当前时间，格式 yyyy/MM/dd HH:mm:ss
        String timeStamp = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss").format(Calendar.getInstance().getTime());

        // 添加新的一行数据到 Table
        TableRow newRow = pressureData.addRow();
        newRow.setString("Time", timeStamp);
        newRow.setFloat("Left", leftPressure);
        newRow.setFloat("Right", rightPressure);

        // 保存更新的 Table 到 CSV 文件
        saveTable(pressureData, fileName);

        // 重新读取 CSV 文件数据，确保读取的数据是最新的
        pressureData = loadTable(fileName, "header");
        numRows = pressureData.getRowCount();

        // 如果左侧压力过高，显示警告信息
        if (isPressureHighLeft) {
          fill(0);  // 设置警告字体颜色为红色
          textSize(48);
          text("Left step off", 200, 550);
        } else {
          fill(255, 0, 0);  // 设置警告字体颜色为红色
          textSize(48);
          text("Left step on", 200, 550);
        }

        // 如果右侧压力过高，显示警告信息
        if (isPressureHighRight) {
          fill(0);  // 设置警告字体颜色为绿色
          textSize(48);
          text("Right step off", 400, 550);
        } else {
          fill(0, 0, 255);  // 设置警告字体颜色为蓝色
          textSize(48);
          text("Right step on", 400, 550);
        }

        delay(300);  // 延迟以便可以读取新的数据
      }
    }
  }
}

void keyPressed() {
  // 当按下 Q 时退出程序
  if (key == 'Q' || key == 'q') {
    exit();  // 退出程序
  }
}

// 检查表格是否包含指定列
boolean hasColumn(Table table, String columnName) {
  String[] columns = table.getColumnTitles();
  for (String col : columns) {
    if (col.equals(columnName)) {
      return true;
    }
  }
  return false;
}
