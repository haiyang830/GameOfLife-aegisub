# GameOfLife-aegisub
aegisub template

aegisub细胞自动机模版

需要先配置config表

主要配置项：  
    t: 设置开始/结束时间  
    size: 设置地图大小  
    distance: 设置细胞间距距离  
    speed: 设置细胞迭代速度  
    shape: 设置细胞生存/死亡的图形  

可选配置项：  
    pos: 设置地图生成坐标  
    border: 设置地图边界距离  
    state: 设置输出细胞类型 
    mode: 设置为逆向迭代  
    rule: 设置游戏规则  
    custum: 设置自定义地图  
    offset: 设置自定义地图相对于世界的偏移值  

具体用法说明详见lua文件与template.ass

默认随机世界测试  
gameOfLife(config)  
![默认随机世界](https://github.com/haiyang830/GameOfLife-aegisub/blob/master/gif/test%20random%20world.gif)

自定地图1测试  
gameOfLife(config,test1)  
![自定地图1测试](https://github.com/haiyang830/GameOfLife-aegisub/blob/master/gif/test1.gif)

自定地图2测试  
gameOfLife(config,test2)  
![自定地图2测试](https://github.com/haiyang830/GameOfLife-aegisub/blob/master/gif/test2.gif)

自定地图1 反向输出测试  
gameOfLife(config,test1) config.state="die"  
![自定地图1 反向输出测试](https://github.com/haiyang830/GameOfLife-aegisub/blob/master/gif/world-test1%20state-die.gif)

自定地图2 逆向迭代测试  
gameOfLife(config,test2) config.mode="reverse"  
![自定地图2 逆向迭代测试](https://github.com/haiyang830/GameOfLife-aegisub/blob/master/gif/world-test2%20mode-reverse.gif)
