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

PFont fontEnglish; // 英文字体对象
PFont fontChinese; // 中文字体对象
int lastTime = 0;  // 上次更新BPM的时间

PImage[] images = new PImage[9];  // 图片数组，用于轮播
int currentImageIndex = 0;  // 当前显示的图片索引
int lastImageChangeTime = 0;  // 上次更换图片的时间

void setup() {
  size(1000, 750);

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

  // 加载字体
  try {
    fontEnglish = createFont("Arial", 32);
    fontChinese = createFont("Microsoft JhengHei", 32); // 微軟正黑體
  } catch (Exception e) {
    println("Failed to load specified fonts. Using default font.");
    String[] availableFonts = PFont.list();
    fontEnglish = createFont(availableFonts[0], 32); 
    fontChinese = fontEnglish; 
  }

  // 加载10张PNG图片
  for (int i = 0; i < 9; i++) {
    String imagePath = "image" + (i + 1) + ".jpg";  // 生成图片文件路径
    images[i] = loadImage(imagePath);
  }
}

void draw() {
  // 每帧都绘制背景和按钮，确保显示内容不会闪烁或被覆盖
  if (isRunning && millis() - lastImageChangeTime >= 500) {
    // 每0.5秒切换图片
    currentImageIndex = (currentImageIndex + 1) % images.length;
    lastImageChangeTime = millis();
  }

  // 绘制背景图片
  image(images[currentImageIndex], 0, 0, width, height);

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
  textFont(fontChinese);
  fill(0);
  textSize(30);
  textAlign(LEFT, BASELINE);
  text("目前 BPM：" + nf(currentBPM, 1, 2), 50, 50);

  // 显示警告信息
  if (isWarning) {
    fill(255, 0, 0);
    textSize(30);
    text("警告：速度不在 180 BPM 範圍內！", 50, 150);
  }
}

void drawButtons() {
  // Start 按钮
  textFont(fontChinese);
  fill(0, 0, 255);
  rect(100 + 200, 500 - 200, 150, 50, 20);  // X 轴加 100, Y 轴减 200
  fill(255);
  textSize(20);
  textAlign(CENTER, CENTER);
  text("開始", 175 + 200, 525 - 200);  // X 轴加 100, Y 轴减 200

  // Stop 按钮
  fill(255, 0, 0);
  rect(300 + 250, 500 - 200, 150, 50, 20);  // X 轴加 100, Y 轴减 200
  fill(255);
  text("停止", 375 + 250, 525 - 200);  // X 轴加 100, Y 轴减 200
}


void drawPressureCircles() {
  float circleSize = 100; // 定義圓圈的大小（直徑）

  // 如果程序正在運行
  if (isRunning) {
    // 判斷左腳的壓力是否超過閾值
    if (isPressureHighLeft) 
      fill(0); // 如果超過，將圓填充為黑色(無)
    else 
      fill(255, 165, 0); // 否則填充為橘色(有)
    // 左圓形位置增加 X 軸 50，Y 軸 300
    ellipse(width / 3 + 50, height / 2 + 300, circleSize, circleSize);

    // 判斷右腳的壓力是否超過閾值
    if (isPressureHighRight) 
      fill(0); // 如果超過，將圓填充為黑色(無)
    else 
      fill(0, 255, 100); // 否則填充為綠色(有)
    ellipse(2 * width / 3-50, height / 2+300, circleSize, circleSize); // 繪製右側圓圈

    // 設定字體填充顏色為白色，用於顯示文字
    fill(255); 
    textFont(fontEnglish); // 設置英文字體
    textSize(32); // 設置文字大小為32像素
    textAlign(CENTER, CENTER); // 設置文字對齊方式為居中

    // 左文字位置增加 X 軸 50，Y 軸 300
    text("L", width / 3 + 50, height / 2 + 300); 
    // 右文字保持原位置
    text("R", 2 * width / 3-50, height / 2+300); 
  } else { 
    // 如果程序未運行，繪製黑色的圓圈作為默認顯示
    fill(0); 
    // 左圓形位置增加 X 軸 50，Y 軸 300
    ellipse(width / 3 + 50, height / 2 + 300, circleSize, circleSize); 
    ellipse(2 * width / 3-50, height / 2+300, circleSize, circleSize); // 繪製右側圓圈
  }
}


void mousePressed() {
  // 修改后的开始按钮区域
  if (mouseX > (100 + 200) && mouseX < (250 + 200) && mouseY > (500 - 200) && mouseY < (550 - 200)) {
    isRunning = true;
    println("開始");
    if (bgMusic != null && !bgMusic.isPlaying()) bgMusic.loop();
  }

  // 修改后的停止按钮区域
  if (mouseX > (300 + 250) && mouseX < (450 + 250) && mouseY > (500 - 200) && mouseY < (550 - 200)) {
    isRunning = false;
    println("停止");
    if (bgMusic != null && bgMusic.isPlaying()) bgMusic.pause();
  }
}


void stop() {
  if (bgMusic != null) bgMusic.close();
  minim.stop();
  super.stop();
}
