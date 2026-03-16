//
//  ViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
}
/*
- (void)recognizeHandwrittenLetterFromImage:(UIImage *)image completion:(void (^)(NSString * _Nullable))completion {
    // 加载你的 Core ML 模型
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"YourLetterRecognitionModel" withExtension:@"mlmodelc"];
    NSError *error;
    VNCoreMLModel *model = [VNCoreMLModel modelForMLModel:[[[MLModel alloc] initWithContentsOfURL:modelURL error:&error] error:&error];
    if (error) {
        completion(nil);
        return;
    }
    
    VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:model completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        NSArray *results = request.results;
        if (error || !results || results.count == 0) {
            completion(nil);
            return;
        }
        
        VNClassificationObservation *topResult = results[0];
        completion(topResult.identifier);
    }];
    
    CGImageRef cgImage = image.CGImage;
    if (!cgImage) {
        completion(nil);
        return;
    }
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage options:@{}];
    [handler performRequests:@[request] error:&error];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.canvasView = [[PKCanvasView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.canvasView];
}

- (UIImage *)getDrawingImage {
    PKDrawing *drawing = self.canvasView.drawing;
    return [drawing imageFromRect:drawing.bounds scale:[UIScreen mainScreen].scale];
}
- (void)verifyLetterOnServerWithImage:(UIImage *)image
                       expectedLetter:(NSString *)expectedLetter
                           completion:(void (^)(BOOL))completion {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    if (!imageData) {
        completion(NO);
        return;
    }
    
    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    NSURL *url = [NSURL URLWithString:@"https://your-api.com/verify-letter"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    NSMutableData *body = [NSMutableData data];
    
    // 添加预期字母
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"expected_letter\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[expectedLetter dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 添加图像数据
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"image\"; filename=\"letter.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    request.HTTPBody = body;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || !data) {
            completion(NO);
            return;
        }
        
        NSError *jsonError;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError || !result[@"isCorrect"]) {
            completion(NO);
            return;
        }
        completion([result[@"isCorrect"] boolValue]);
    }];
    [task resume];
}

- (IBAction)verifyButtonTapped:(id)sender {
    UIImage *drawingImage = self.drawingImageView.image;
    NSString *expectedLetter = @"A"; // 从UI获取
    // 先进行本地验证
    [self recognizeHandwrittenLetterFromImage:drawingImage completion:^(NSString * _Nullable recognizedLetter) {
        if ([recognizedLetter isEqualToString:expectedLetter]) {
            NSLog(@"本地验证通过");
            // 本地验证通过后再进行服务器验证
            [self verifyLetterOnServerWithImage:drawingImage expectedLetter:expectedLetter completion:^(BOOL isCorrect) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (isCorrect) {
                        NSLog(@"服务器验证通过");
                        // 更新UI显示验证成功
                    } else {
                        NSLog(@"服务器验证失败");
                        // 更新UI显示验证失败
                    }
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"本地验证失败");
                // 更新UI显示验证失败
            });
        }
    }];
}
*/
@end

