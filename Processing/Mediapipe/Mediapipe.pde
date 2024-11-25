// 導入必要函式庫
import gab.opencv.*;
import processing.video.*;
import java.util.ArrayList;

Capture cam; // 攝影機物件
OpenCV opencv; // OpenCV 物件

void setup() {
  size(640, 480); // 設置視窗大小
  
  // 初始化攝影機
  cam = new Capture(this, 640, 480);
  cam.start(); // 啟動攝影機
  
  // 初始化 OpenCV 並啟用背景減法
  opencv = new OpenCV(this, 640, 480);
  opencv.startBackgroundSubtraction(5, 3, 0.5);
}

void draw() {
  background(0); // 設置背景為黑色
  
  if (cam.available() == true) { // 檢查攝影機是否有新影像
    cam.read(); // 讀取攝影機影像
    opencv.loadImage(cam); // 將影像載入到 OpenCV
    opencv.updateBackground(); // 更新背景資訊
    opencv.difference(); // 計算影像差異
    
    // 顯示處理後的影像
    image(opencv.getOutput(), 0, 0);
    
    // 偵測輪廓
    ArrayList<Contour> contours = opencv.findContours();
    stroke(0, 255, 0); // 設置輪廓顏色為綠色
    strokeWeight(2); // 設置輪廓線條寬度
    noFill(); // 不填充輪廓區域
    
    for (Contour contour : contours) {
      contour.draw(); // 在畫面上繪製輪廓
    }
  }
}
