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

int leftFootSteps = 0;  // 左脚步伐计数
int rightFootSteps = 0;  // 右脚步伐计数
float currentBPM = 0;  // 当前BPM
boolean isWarning = false;  // 警告状态

PFont font; // 字体对象
int lastTime = 0;  // 上次更新BPM的时间

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

  // 初始化串口
  if (Serial.list().length > 0) {
    String portName = Serial.list()[0];
    myPort = new Serial(this, portName, 9600);
    println("Connected to serial port: " + portName);
  } else {
    println("No serial ports available.");
  }

  // 初始化 Minim 并加载音频文件
  minim = new Minim(this);
  bgMusic = minim.loadFile("background_music.mp3"); // 确保音频文件位于 sketch 文件夹中
  if (bgMusic == null) {
    println("Failed to load background_music.mp3. Ensure the file exists in the sketch/data directory.");
    println("Consider converting the file to WAV format if the issue persists.");
  } else {
    println("Audio file loaded successfully.");
  }

  // 加载支持中文的字体
  try {
    font = createFont("Arial Unicode MS", 32);
  } catch (Exception e) {
    println("Arial Unicode MS is not available. Switching to a default font.");
    String[] availableFonts = PFont.list();
    font = createFont(availableFonts[0], 32); // 使用第一个可用字体
  }
  textFont(font);
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

        // 计算步伐
        if (isPressureHighLeft) leftFootSteps++;
        if (isPressureHighRight) rightFootSteps++;

        // 每1000毫秒（1秒）更新BPM
        if (millis() - lastTime >= 1000) {
          currentBPM = (leftFootSteps + rightFootSteps) * 30; // 每分钟步伐数
          leftFootSteps = 0;  // 重置步伐计数
          rightFootSteps = 0; // 重置步伐计数
          lastTime = millis(); // 更新上次更新时间
          
          // 检查是否在180 BPM范围内
          isWarning = (currentBPM < 170 || currentBPM > 190);
        }

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

  // 显示当前BPM
  fill(0);
  textSize(32);
  text("当前 BPM: " + nf(currentBPM, 1, 2), 50, 150);
  
  // 显示警告信息
  if (isWarning) {
    fill(255, 0, 0);
    textSize(32);
    text("警告: 频率不在180 BPM范围内!", 50, 200);
  }
}

void drawButtons() {
  // Start 按钮
  fill(0, 255, 0);
  rect(100, 500, 150, 50);
  fill(255);
  textSize(20);
  text("开始", 135, 535);

  // Stop 按钮
  fill(255, 0, 0);
  rect(300, 500, 150, 50);
  fill(255);
  textSize(20);
  text("停止", 345, 535);
}

void drawPressureCircles() {
  if (isRunning) {
    if (isPressureHighLeft) fill(255, 0, 0); else fill(0);
    ellipse(width / 3, height / 2, 200, 200);

    if (isPressureHighRight) fill(0, 255, 0); else fill(0, 0, 255);
    ellipse(2 * width / 3, height / 2, 200, 200);

    fill(0);
    textSize(32);
    text("左脚压力: " + nf(leftPressure, 1, 2), 50, 50);
    text("右脚压力: " + nf(rightPressure, 1, 2), 50, 100);
  } else {
    fill(0);
    ellipse(width / 3, height / 2, 200, 200);
    ellipse(2 * width / 3, height / 2, 200, 200);

    fill(0);
    textSize(32);
    text("左脚压力: 尚未量测", 50, 50);
    text("右脚压力: 尚未量测", 50, 100);
  }
}

void mousePressed() {
  if (mouseX > 100 && mouseX < 250 && mouseY > 500 && mouseY < 550) {
    isRunning = true;
    println("开始");
    if (bgMusic != null && !bgMusic.isPlaying()) bgMusic.loop(); // 播放背景音乐
  }

  if (mouseX > 300 && mouseX < 450 && mouseY > 500 && mouseY < 550) {
    isRunning = false;
    println("停止");
    if (bgMusic != null && bgMusic.isPlaying()) bgMusic.pause(); // 停止背景音乐
  }
}

void stop() {
  if (bgMusic != null) bgMusic.close();
  minim.stop();
  super.stop();
}
