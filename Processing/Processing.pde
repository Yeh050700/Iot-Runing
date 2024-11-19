import java.text.SimpleDateFormat;
import java.util.Calendar;
import processing.serial.*;
import ddf.minim.*;

Serial myPort;  // 串口对象
float leftPressure = 0;  // Left 压力数据（初始化为 0）
float rightPressure = 0;  // Right 压力数据（初始化为 0）
Table pressureData;
boolean isPressureHighLeft = false;
boolean isPressureHighRight = false;
boolean isRunning = false;  // 是否正在运行

Minim minim;  // Minim 音频库对象
AudioPlayer bgMusic;  // 背景音乐播放器
String fileName;  // 动态生成的 CSV 文件名

void setup() {
  size(800, 600);

  // 动态生成 CSV 文件名
  String timeStamp = new SimpleDateFormat("yyyy-MM-dd-HH-mm-ss").format(Calendar.getInstance().getTime());
  fileName = "pressure_data_" + timeStamp + ".csv";

  // 创建新的 Table 并添加标题
  pressureData = new Table();
  pressureData.addColumn("Time");
  pressureData.addColumn("Left");
  pressureData.addColumn("Right");

  if (Serial.list().length > 0) {
    String portName = Serial.list()[0];
    myPort = new Serial(this, portName, 9600);
  } else {
    println("No serial ports available.");
  }

  // 初始化 Minim 并加载音频文件
  minim = new Minim(this);
  bgMusic = minim.loadFile("background_music.mp3"); // 确保音频文件位于 sketch 文件夹中
}

void draw() {
  // 每帧都绘制背景和按钮，确保显示内容不会闪烁或被覆盖
  background(200);

  // 绘制按钮
  drawButtons();

  // 绘制状态（根据当前压力数据）
  drawPressureCircles();

  // 如果程序正在运行，则读取串口数据
  if (isRunning && myPort != null && myPort.available() > 0) {
    String inString = myPort.readStringUntil('\n');
    if (inString != null) {
      inString = trim(inString);
      String[] pressures = split(inString, ',');
      if (pressures.length == 2) {
        leftPressure = float(pressures[0]);
        rightPressure = float(pressures[1]);

        // 更新状态
        isPressureHighLeft = leftPressure > 1000;
        isPressureHighRight = rightPressure > 1000;

        // 保存数据到 CSV 文件
        String currentTime = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss").format(Calendar.getInstance().getTime());
        TableRow newRow = pressureData.addRow();
        newRow.setString("Time", currentTime);
        newRow.setFloat("Left", leftPressure);
        newRow.setFloat("Right", rightPressure);

        // 保存到动态生成的文件中
        saveTable(pressureData, fileName);
      }
    }
  }
}

void drawButtons() {
  // Start 按钮
  fill(0, 255, 0);
  rect(100, 500, 150, 50);
  fill(255);
  textSize(20);
  text("Start", 135, 535);

  // Stop 按钮
  fill(255, 0, 0);
  rect(300, 500, 150, 50);
  fill(255);
  textSize(20);
  text("Stop", 345, 535);
}

void drawPressureCircles() {
  // 如果正在运行，显示实时数据，否则显示默认状态
  if (isRunning) {
    // 左侧压力圆
    if (isPressureHighLeft) fill(255, 0, 0); else fill(0);
    ellipse(width / 3, height / 2, 200, 200);

    // 右侧压力圆
    if (isPressureHighRight) fill(0, 255, 0); else fill(0, 0, 255);
    ellipse(2 * width / 3, height / 2, 200, 200);

    // 显示压力值
    fill(0);
    textSize(32);
    text("Left Pressure: " + nf(leftPressure, 1, 2), 50, 50);
    text("Right Pressure: " + nf(rightPressure, 1, 2), 50, 100);
  } else {
    // 停止状态：显示默认值并将圆圈颜色改为黑色
    fill(0);
    ellipse(width / 3, height / 2, 200, 200);
    ellipse(2 * width / 3, height / 2, 200, 200);

    // 显示尚未量测的提示
    fill(0);
    textSize(32);
    text("Left Pressure: 尚未量測", 50, 50);
    text("Right Pressure: 尚未量測", 50, 100);
  }
}

void mousePressed() {
  // 检查是否点击了“开始”按钮
  if (mouseX > 100 && mouseX < 250 && mouseY > 500 && mouseY < 550) {
    isRunning = true;
    println("Started");
    if (!bgMusic.isPlaying()) bgMusic.loop(); // 播放背景音乐
  }

  // 检查是否点击了“结束”按钮
  if (mouseX > 300 && mouseX < 450 && mouseY > 500 && mouseY < 550) {
    isRunning = false;
    println("Stopped");
    if (bgMusic.isPlaying()) bgMusic.pause(); // 停止背景音乐
  }
}

// 确保程序关闭时释放音频资源
void stop() {
  bgMusic.close();
  minim.stop();
  super.stop();
}
