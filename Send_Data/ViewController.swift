//
//  ViewController.swift
//  Send_Data
//
//  Created by 菊池修也 on 2016/10/01.
//  Copyright © 2016年 菊池修也. All rights reserved.
//

import UIKit
import CoreMotion
import CFNetwork

class ViewController: UIViewController, StreamDelegate {
    
    @IBOutlet weak var TextField: UITextField!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(TextField.isFirstResponder){
            TextField.resignFirstResponder()
        }
    }

    @IBOutlet weak var Dig_Data_Label: UILabel!
    
    @IBOutlet weak var cal_Data_Label: UILabel!
    
    @IBOutlet weak var status_Label: UILabel!
    
    @IBAction func connection_button(_ sender: AnyObject) {
        if(self.status_Label.text == "停止中"){
            //受信用のタイマー生成
            receiveTimer = Timer.scheduledTimer(timeInterval: 0.6, target: self, selector:#selector(ViewController.timer_receive_data) , userInfo: nil, repeats: true)
            //接続確認処理
            confirmation_timer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(ViewController.confirm), userInfo: nil, repeats: false)
            
            
            connect()
            
            //タッチイベントoff
            UIApplication.shared.beginIgnoringInteractionEvents()
            //self.status_Label.text = "待機中"
        }else{
            //アラート処理
            let alert:UIAlertController = UIAlertController(title:"警告", message:"待機中に実行してください", preferredStyle:UIAlertControllerStyle.alert)
            
            let defaultAction:UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:{ (action:UIAlertAction!) -> Void in print("OK") })
            
            alert.addAction(defaultAction)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func send_Button(_ sender: AnyObject) {
        if(self.status_Label.text == "待機中"){
            Gyro_Data()
            start_Timer()
            self.status_Label.text = "送信中"
        }else{
            //アラート処理
            let alert:UIAlertController = UIAlertController(title:"警告", message:"待機中に実行してください", preferredStyle:UIAlertControllerStyle.alert)
            
            let defaultAction:UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:{ (action:UIAlertAction!) -> Void in print("OK") })
            
            alert.addAction(defaultAction)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func disconnect_button(_ sender: AnyObject) {
        if(self.status_Label.text == "送信中"){
            Stop_Gyro()
            stop_timer()
            inputStream.close()
            outputStream.close()
            self.status_Label.text = "停止中"
            self.status_Label.backgroundColor = UIColor.red
            self.confirm_flag = 0
        }else{
            //アラート処理
            let alert:UIAlertController = UIAlertController(title:"警告", message:"送信中に実行してください", preferredStyle:UIAlertControllerStyle.alert)
            
            let defaultAction:UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:{ (action:UIAlertAction!) -> Void in print("OK") })
            
            alert.addAction(defaultAction)

            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func cal_button(_ sender: AnyObject) {
        if(self.status_Label.text == "送信中"){
            Gyro_Data()
        }else{
            //アラート処理
            let alert:UIAlertController = UIAlertController(title:"警告", message:"送信中に実行してください", preferredStyle:UIAlertControllerStyle.alert)
            
            let defaultAction:UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:{ (action:UIAlertAction!) -> Void in print("OK") })
            
            alert.addAction(defaultAction)

            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func test_dig_data(_ sender: AnyObject) {
        Gyro_Data()
        
        //誤差出力用タイマー
        thirty_ms_timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(ViewController.output_loss), userInfo: nil, repeats: true)
        
    }
    
    @IBAction func test_stop_button(_ sender: AnyObject) {
        thirty_ms_timer.invalidate()
        Stop_Gyro()
    }
    

    //-------------------------------------------------------------------------
    //描写処理
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //--------------------------------------------------------------------------
    
    
    
    //instance
    var motionmaneger:CMMotionManager!
    
    //変数宣言
    var Data_Yaw:Double = 0.0
    var Dig_Data:Double = 0.0
    var Data_Yaw_2:Int = 0
    var confirm_flag = 0
    var tmp_loss_data:Double = 0.0
    var loss:Double = 0.0
    
    //IPアドレスとポート番号 -> できればデータベースで管理
    var serverAddress:CFString = "192.168.12.12" as CFString
    let serverPort:UInt32 = 7000
    
    //stream宣言
    fileprivate var inputStream:InputStream!
    fileprivate var outputStream:OutputStream!
    
    //timerインスタンス生成
    var timer = Timer()
    var receiveTimer = Timer()
    var confirmation_timer = Timer()
    var thirty_ms_timer = Timer()
    
    //センサーの値を読み取る
    func Gyro_Data(){
        //print("debug")
        
        motionmaneger = CMMotionManager()
        motionmaneger.deviceMotionUpdateInterval = 0.02
        
        motionmaneger.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {(gyrodata,error) in
            if let e = error{
                print(e.localizedDescription)
                return
            }
            guard let data = gyrodata else {
                return
            }
            
            self.Dig_Data = data.attitude.yaw * 180 / M_PI
            
            //----------追加-----------------
            if(self.Dig_Data >= 0){
                self.Dig_Data = self.Dig_Data + 2.5
            }else{
                self.Dig_Data = self.Dig_Data + 2.5
            }
            //------------------------------
            
            
            self.Data_Yaw = self.Dig_Data/5
            
            if (self.Data_Yaw >= 0){
                self.Data_Yaw_2 = Int(self.Data_Yaw) + 1;
                if(self.Data_Yaw_2 == 73){
                    self.Data_Yaw_2 = 1
                }
            }else{
                self.Data_Yaw_2 = 72 - Int(abs(self.Data_Yaw))
                if(self.Data_Yaw == 0){
                    self.Data_Yaw_2 = 1
                }
            }
            
            self.Dig_Data_Label.text = String("\(self.Dig_Data)")
            self.cal_Data_Label.text = String("\(self.Data_Yaw_2)")
        })
    }
    
    func Stop_Gyro(){
        motionmaneger.stopDeviceMotionUpdates()
    }
    
    //送信処理開始
    func start_Timer(){
        //データ送信用タイマー
        timer = Timer.scheduledTimer(timeInterval: 0.04, target: self, selector:#selector(ViewController.timer_send_data), userInfo: nil, repeats: true)
        
    }
    
    //tcp通信　受信用関数
    func timer_receive_data(){
        if(self.inputStream.hasBytesAvailable){
            let bufferSize = 1
            var buffer = Array<UInt8>(repeating: 0, count: bufferSize)
            _ = inputStream.read(&buffer, maxLength: bufferSize)
            let read_data = String(bytes:buffer, encoding:String.Encoding.utf8)
            
            if (read_data == "r"){
                Gyro_Data()
            }else if(read_data == "s"){
                //接続確認用
                self.confirm_flag = 1
                self.status_Label.text = "待機中"
                self.status_Label.backgroundColor = UIColor.green
            }
        }
    }
    
    //30秒ごとの誤差
    func output_loss(){
        if (self.tmp_loss_data != 0.0) {
            self.loss = tmp_loss_data - self.Dig_Data
        }
        
        self.tmp_loss_data = self.Dig_Data
        
        print(self.loss)
    }
    
    
    //接続確認用関数
    func confirm(){
        //タッチイベントon
        UIApplication.shared.endIgnoringInteractionEvents()
        
        //サーバー側から s が送られてきたか判定
        if(self.confirm_flag == 1){
            print("接続完了")
        }else if(self.confirm_flag == 0){
            //self.confirmation_timer.invalidate()
            let alert:UIAlertController = UIAlertController(title:"警告", message:"接続失敗", preferredStyle:UIAlertControllerStyle.alert)
            
            let defaultAction:UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:{ (action:UIAlertAction!) -> Void in print("OK") })
            
            alert.addAction(defaultAction)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    //timer実行関数　tcp通信処理内容
    func timer_send_data(){
        var buf:UInt8 = UInt8(self.Data_Yaw_2)
        
        self.outputStream!.write(&buf, maxLength: 1)
    }
    
    func stop_timer(){
        if(timer.isValid){
            timer.invalidate()
            receiveTimer.invalidate()
        }
    }
    
    //client接続
    func connect(){
        print("connecting...")
        
        //※エラー処理追加
        
        serverAddress = TextField.text as! CFString
        
        var readStream:Unmanaged<CFReadStream>?
        var writeStream:Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(nil, self.serverAddress, self.serverPort, &readStream, &writeStream)
        
        self.inputStream = readStream!.takeRetainedValue()
        self.outputStream = writeStream!.takeRetainedValue()
        
        self.inputStream.delegate = self
        self.outputStream.delegate = self
        
        self.inputStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        self.outputStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        self.inputStream.open()
        self.outputStream.open()
        
        print("connect success")
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        
    }
}

