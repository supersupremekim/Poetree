//
//  FirstViewController.swift
//  Poetree
//
//  Created by 김동환 on 2021/08/21.
//

import UIKit
import AVFoundation
import Firebase
import AuthenticationServices
import RxSwift
import RxCocoa
import NSObject_Rx



class UserRegisterViewController: UIViewController, ViewModelBindable, StoryboardBased {
    
    
    var viewModel: UserRegisterViewModel!
    @IBOutlet weak var logoImage: UIImageView!
    
    
    // ------------------------------ AVPlayer
    
    @IBOutlet weak var videoLayer: UIView!
    var avPlayerLooper: AVPlayerLooper!
    var avQueuePlayer: AVQueuePlayer!
    let asset = AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "shadow", ofType: "mp4")!))
    
    
    // ------------------------------ PenNameSettingView
    @IBOutlet weak var penNameTextField: UITextField!
    var penname: String?
    @IBOutlet weak var penNameStackView: UIStackView!
    @IBOutlet weak var pennameCompleteBtn: UIButton!
    @IBOutlet weak var validCheckLabel: UILabel!
    
    
    // ------------------------------ regiserView
    @IBOutlet weak var registerStackView: UIStackView!
    @IBOutlet weak var googleLogInBtn: UIButton!
    @IBOutlet weak var appleLogInBtn: UIButton!
    @IBOutlet weak var facebookLogInBtn: UIButton!
    @IBOutlet weak var selectLoginLabel: UILabel!
    
    // ------------------------------ chooseOptionView
    @IBOutlet weak var optionStackView: UIStackView!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var registerBtn: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        playVideo()
        setupBtn()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.systemOrange
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
            navigationController?.navigationBar.shadowImage = nil
    }
    
    
    func configureUI(){
        
        pennameCompleteBtn.isEnabled = false
        penNameTextField.borderStyle = .none
        let border = CALayer()
        border.frame = CGRect(x: 0, y: penNameTextField.frame.size.height - 1, width: penNameTextField.frame.width, height: 1)
        border.backgroundColor = UIColor.lightGray.cgColor
        penNameTextField.layer.addSublayer(border)
        
        loginBtn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)
        loginBtn.layer.cornerRadius = 8
        
        registerBtn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)
        registerBtn.layer.cornerRadius = 8
        
        
    }
    
    func setupBtn(){
        
        appleLogInBtn.addTarget(self, action: #selector(performAppleSignIn), for: .touchUpInside)
    }
    
    func bindViewModel() {
        
        googleLogInBtn.rx.tap
            .subscribe { [weak self] _ in
                
                guard let self = self else {return}
                
                self.viewModel.userService.googleRegister(penname: self.penname, presentingVC: self) { result in
                    self.handleLogInResult(result)
                }
            }
            .disposed(by: rx.disposeBag)
        
        
        facebookLogInBtn.rx.tap
            .subscribe { [weak self] _ in
                
                guard let self = self else {return}
                
                self.viewModel.userService.facebookRegister(penname: self.penname, presentingVC: self) { result in
                    self.handleLogInResult(result)
                }
                
            }
            .disposed(by: rx.disposeBag)
        
        penNameTextField.rx.text.orEmpty
            .bind(to: viewModel.input.pennameInput)
            .disposed(by: rx.disposeBag)
        
        viewModel.output.isCompleteBtnValid
            .drive(self.pennameCompleteBtn.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.output.validLetter
            .drive(self.validCheckLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
    }
    
    
    func playVideo() {
        
        let item = AVPlayerItem(asset: asset)
        self.avQueuePlayer = AVQueuePlayer(playerItem: item)
        self.avPlayerLooper = AVPlayerLooper(player: self.avQueuePlayer, templateItem: item)
        
        let layer = AVPlayerLayer(player: self.avQueuePlayer)
        
        layer.frame = self.view.bounds
        layer.videoGravity = .resizeAspectFill
        self.videoLayer.layer.addSublayer(layer)
        
        avQueuePlayer.play()
        
        self.videoLayer.bringSubviewToFront(self.logoImage)
        self.videoLayer.bringSubviewToFront(self.optionStackView)
        self.videoLayer.sendSubviewToBack(self.registerStackView)
        self.videoLayer.sendSubviewToBack(self.penNameStackView)
        self.optionStackView.isHidden = false
        
    }
    
    @IBAction func logInBtnTapped(_ sender: UIButton) {
        self.videoLayer.bringSubviewToFront(self.registerStackView)
        self.registerStackView.isHidden = false
        self.videoLayer.sendSubviewToBack(self.optionStackView)
    }
    
    
    @IBAction func registerBtnTapped(_ sender: UIButton) {
        self.videoLayer.bringSubviewToFront(self.penNameStackView)
        self.penNameStackView.isHidden = false
        self.videoLayer.sendSubviewToBack(self.optionStackView)
    }
    
    
    @IBAction func pennameCompleteBtnTapped(_ sender: Any) {
        self.penname = penNameTextField.text
        self.videoLayer.sendSubviewToBack(self.penNameStackView)
        self.videoLayer.bringSubviewToFront(self.registerStackView)
        self.registerStackView.isHidden = false
        self.penNameTextField.resignFirstResponder()
    }
    
    
    @IBAction func backBtnTapped(_ sender: UIButton) {
        self.videoLayer.sendSubviewToBack(registerStackView)
        self.videoLayer.bringSubviewToFront(penNameStackView)
    }
    
    
    
    func handleLogInResult(_ result: Result<CurrentAuth, SignInErorr>) {
        DispatchQueue.main.async {
            switch result {
            case .success:
                
                self.navigationController?.popViewController(animated: true)
            case .failure(let error):
                
                switch error{
                case .LoginError(let error):
                    self.loginErrorHandle(error: error)
                case .RegisterError(let error):
                    //에러 핸들링 필요
                    self.registerErrorHandle(error: error)
                    break
                }
            }
        }
    }
    
    func loginErrorHandle(error: LoginError){
        
        switch error {
        case .newUser:
            self.firstUserHandle()
            break
        case .logInError:
            //에러 핸들링 필요
            break
        case .flatFormError:
            self.flatformErrorHandle()
        }
    }
    
    func registerErrorHandle(error: RegisterError){
        switch error {
        case .flatFormError:
            self.flatformErrorHandle()
        default:
            break
        }
    }
    
    func firstUserHandle() {
        
        let alert = UIAlertController(title: "회원 정보 없음", message: "필명과 함께 회원 가입을 먼저 해주세요", preferredStyle: .alert)
        let action = UIAlertAction(title: "확인", style: .default) { action in
            
            self.viewModel.userService.deleteUser()
            
            DispatchQueue.main.async{
                self.videoLayer.sendSubviewToBack(self.registerStackView)
                self.videoLayer.bringSubviewToFront(self.penNameStackView)
                self.penNameStackView.isHidden = false
            }
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func flatformErrorHandle() {
        self.avQueuePlayer.play()
        let alert = UIAlertController(title: "로그인 플랫폼 오류", message: "기존에 회원가입한 SNS 플랫폼이 아닙니다\n기존에 회원가입한 플랫폼을 선택해주세요", preferredStyle: .alert)
        let action = UIAlertAction(title: "확인", style: .default) { action in
            
            self.viewModel.userService.deleteUser()
            DispatchQueue.main.async {
                self.avQueuePlayer.play()
            }
            
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
 
    
}

//MARK: ----------------------AppleLogin

extension UserRegisterViewController {
    
    @objc func performAppleSignIn(){
        let request = createAppleIDRequest()
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        authorizationController.performRequests()
    }
    
    func createAppleIDRequest() -> ASAuthorizationAppleIDRequest {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        
        let nonce = randomNonceString()
        request.nonce = sha256(nonce)
        currentNonce = nonce
        return request
    }
}


extension UserRegisterViewController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("no login request was sent")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {print("unable to fetch id token")
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {print("idTokenString error")
                return}
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            self.viewModel.userService.appleRegister(penname: penname, credential: credential) { result in
                
                self.handleLogInResult(result)
            }
        }
    }
}


extension UserRegisterViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
