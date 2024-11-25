import React, { useEffect, useRef, useState } from 'react';
import { Pose } from '@mediapipe/pose';
import { Camera } from '@mediapipe/camera_utils';
import { drawConnectors, drawLandmarks } from '@mediapipe/drawing_utils';

const App = () => {
    const [data, setData] = useState(''); // 存储从服务器获取的压力数据
    const [poseData, setPoseData] = useState([]); // 存储腿部关键点的数据
    const videoRef = useRef(null); // 捕获视频流
    const canvasRef = useRef(null); // 绘制追踪结果

    useEffect(() => {
        // 初始化 MediaPipe Pose
        if (!videoRef.current || !canvasRef.current) return;

        const pose = new Pose({
            locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/pose/${file}`,
        });

        pose.setOptions({
            modelComplexity: 1,
            smoothLandmarks: true,
            enableSegmentation: false,
            minDetectionConfidence: 0.5,
            minTrackingConfidence: 0.5,
        });

        pose.onResults((results) => {
            const canvasElement = canvasRef.current;
            const canvasCtx = canvasElement.getContext('2d');

            // 清空画布
            canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);

            // 绘制视频到画布
            canvasCtx.drawImage(
                results.image,
                0,
                0,
                canvasElement.width,
                canvasElement.height
            );

            // 绘制腿部追踪数据（关键点和连接线）
            if (results.poseLandmarks) {
                drawConnectors(canvasCtx, results.poseLandmarks, Pose.POSE_CONNECTIONS, {
                    color: '#00FF00',
                    lineWidth: 4,
                });
                drawLandmarks(canvasCtx, results.poseLandmarks, {
                    color: '#FF0000',
                    lineWidth: 2,
                });

                // 筛选腿部关键点数据（例：髋关节、膝盖、脚踝）
                const legLandmarks = [
                    results.poseLandmarks[23], // 左髋
                    results.poseLandmarks[24], // 右髋
                    results.poseLandmarks[25], // 左膝
                    results.poseLandmarks[26], // 右膝
                    results.poseLandmarks[27], // 左脚踝
                    results.poseLandmarks[28], // 右脚踝
                ];

                // 保存数据
                const currentData = legLandmarks.map((landmark) => ({
                    x: landmark.x.toFixed(4),
                    y: landmark.y.toFixed(4),
                    z: landmark.z.toFixed(4),
                }));

                setPoseData((prevData) => [
                    ...prevData,
                    { pressure: data, landmarks: currentData },
                ]); // 累积记录，同时保存压力值和关键点数据
            }
        });

        // 初始化摄像头
        const camera = new Camera(videoRef.current, {
            onFrame: async () => {
                await pose.send({ image: videoRef.current });
            },
            width: 640,
            height: 480,
        });
        camera.start();

        return () => {
            camera.stop();
        };
    }, [data]);

    useEffect(() => {
        // Fetch 数据逻辑
        const fetchData = async () => {
            try {
                const response = await fetch('http://192.168.255.1:3001/data');
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                const result = await response.json();
                setData(result.pressure); // 更新压力数据
            } catch (error) {
                console.error('Fetch error:', error);
            }
        };

        // 每秒获取一次数据
        const interval = setInterval(fetchData, 1000);

        return () => clearInterval(interval); // 清理定时器
    }, []);

    const downloadCSV = () => {
        // 将 poseData 转换为 CSV 格式
        const headers = ['Frame', 'Pressure', 'Keypoint', 'X', 'Y', 'Z'];
        const rows = poseData.flatMap((frame, frameIndex) =>
            frame.landmarks.map((point, pointIndex) => [
                frameIndex + 1, // 帧编号
                frame.pressure, // 当前帧的压力数据
                pointIndex + 1, // 关键点编号
                point.x, // X 坐标
                point.y, // Y 坐标
                point.z, // Z 坐标
            ])
        );

        const csvContent =
            [headers, ...rows]
                .map((row) => row.join(','))
                .join('\n');

        // 创建下载链接
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = 'pose_and_pressure_data.csv';
        link.click();
    };

    return (
        <div className="App" style={{ textAlign: 'center' }}>
            <h1>Pressure & Pose Tracking</h1>
            <p>Distance: {data}</p>
            {/* 隐藏的视频组件用于捕获摄像头数据 */}
            <video ref={videoRef} style={{ display: 'none' }}></video>
            {/* 用于显示追踪结果 */}
            <canvas
                ref={canvasRef}
                width={640}
                height={480}
                style={{ border: '1px solid black', margin: '20px auto', display: 'block' }}
            ></canvas>
            <button onClick={downloadCSV}>Download Pose & Pressure Data</button>
        </div>
    );
};

export default App;
