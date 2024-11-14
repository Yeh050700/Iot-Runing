import java.io.PrintWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Calendar;

float pressure;
PrintWriter output;
Table pressureData;
int numRows;
String fileName = "pressure_data.csv";

void setup() {
  size(800, 600);
  
  // 設定 CSV 檔案的儲存路徑和名稱
  try {
    FileWriter fw = new FileWriter(fileName, true); // 以附加模式打開檔案
    output = new PrintWriter(fw);
    
    // 如果檔案是空的，寫入標題
    if (new File(fileName).length() == 0) {
      output.println("Time,Pressure (hPa)");
    }
  } catch (IOException e) {
    e.printStackTrace();
  }
  
  // 初始化 CSV 檔案數據
  loadPressureData(fileName);
}

void draw() {
  background(255);
  
  // 繪製當前壓力值
  pressure = random(900, 1100);
  fill(0);
  textSize(32);
  text("Current Pressure: " + nf(pressure, 1, 2) + " hPa", 50, 50);
  
  // 繪製條形圖
  fill(map(pressure, 900, 1100, 0, 255), 0, 0);
  rect(50, 100, 100, pressure - 900);
  
  // 獲取當前時間，格式 yyyy/MM/dd HH:mm:ss
  String timeStamp = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss").format(Calendar.getInstance().getTime());
  
  // 將當前時間和壓力數據寫入 CSV 檔案
  output.println(timeStamp + "," + nf(pressure, 1, 2));
  output.flush();  // 確保所有數據都寫入
  
  // 重新讀取 CSV 檔案數據
  loadPressureData(fileName);
  
  // 繪製 CSV 數據圖表
  for (int i = 0; i < numRows; i++) {
    float csvPressure = pressureData.getFloat(i, "Pressure (hPa)");
    float x = map(i, 0, numRows, 200, width - 50);
    float y = map(csvPressure, 900, 1100, height - 50, 100);
    
    // 繪製圓點
    fill(map(csvPressure, 900, 1100, 0, 255), 0, 0);
    ellipse(x, y, 10, 10);
    
    // 繪製壓力值
    fill(0);
    text(nf(csvPressure, 1, 2) + " hPa", x + 5, y - 5);
  }
  
  delay(300);
}

void keyPressed() {
  // 當按下Q時關閉檔案
  if (key == 'Q' || key == 'q') {
    output.flush();  // 確保所有數據都寫入
    output.close();  // 關閉檔案
    exit();          // 退出程式
  }
}

void loadPressureData(String fileName) {
  pressureData = loadTable(fileName, "header");
  numRows = pressureData.getRowCount();
  println("Number of rows in CSV: " + numRows);
}
