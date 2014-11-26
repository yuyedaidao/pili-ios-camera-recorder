# PLRecorderKit

PLRecorderKit 是为 **pili.io** 流媒体云服务提供的一套 SDK, 旨在解决 iOS 端快速、轻松实现 iOS 设备利用摄像头直播接入，便于 **pili.io** 的开发者专注于产品业务本身，而不必在技术细节上花费不必要的时间。

## 内容摘要

- [1 快速开始](#1-快速开始)
	- [1.1 配置工程](#1.1-配置工程)
		- [1.1.1 二进制包方式](#1.1.1-二进制包方式)
		- [1.1.2 源码方式](#1.1.2-源码方式)
	- [1.2 调用 PLRecorderKit](#1.2-调用-PLRecorderKit)
- [2 版本历史](#2-版本历史)

## 1 快速开始

先来看看 PLRecroderKit 接入的步骤

### 1.1 配置工程
#### 1.1.1 二进制包方式

- 下载 PLRecorderKit 的 release zip 文件；
- 解压后得到 libPLRecorderKit.a 和 其 include 头文件；
- 将 libPLRecorderKit.a 和 include 头文件选中并拖拽到自己的 Xcode 工程中；
- 为工程添加依赖库：
	- AVFoundation.framework
	- AudioToolbox.framework
	- CFNetwork.framework
	- CoreGraphics.framework
	- CoreMedia.framework
	- Foundation.framework
	- OpenGLES.framework
	- VideoToolbox.framewrok
- 为工程添加 search path
	- 在工程的 Build Settings / Header Search Paths 下添加 include 目录的相对路径
- 编译并开始你的工作吧

#### 1.1.2 源码方式

- 暂不提供

### 1.2 调用 PLRecorderKit

在需要的地方添加

```Objective-C
#import <PLRecorderKit/PLRecorderKit.h>
```

PLCaptureManager 是核心类，你只需要关注并使用这个类就可以完成通过摄像头推流、预览的工作

推流前务必要先检查摄像头授权，并记得设置预览界面
```Objective-C
	// 检查摄像头是否有授权
	PLCaptureDeviceAuthorizedStatus status = [PLCaptureManager captureDeviceAuthorizedStatus];
    
    if (PLCaptureDeviceAuthorizedStatusUnknow == status) {
        [PLCaptureManager requestCaptureDeviceAccessWithCompletionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [PLCaptureManager sharedManager].previewView = self.previewView;
                });
            }
        }];
    } else if (PLCaptureDeviceAuthorizedStatusGranted == status) {
        [PLCaptureManager sharedManager].previewView = self.previewView;
    } else {
    	// 处理未授权的情况
    }
```

设置推流地址，这里的推流地址应该是你自己的服务端通过 **pili.io** 请求到的
```Objective-C
    // 设置推流地址
    [PLCaptureManager sharedManager].rtmpPushURL = [NSURL URLWithString:@"YOUR_RTMP_PUSH_URL_HERE"];
```

推流操作
```Objective-C
    // 开始推流
    [[PLCaptureManager sharedManager] connect];
    // 停止推流
    [[PLCaptureManager sharedManager] disconnect];
```

## 2 版本历史

- 1.0.0
	- 完成基本的推流、预览功能