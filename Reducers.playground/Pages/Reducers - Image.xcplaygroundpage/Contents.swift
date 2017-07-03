//: Playground - noun: a place where people can play

import UIKit

func randomGifURL(tag: String? = nil) -> URL {
    return URL(string: "http://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC")!
}

struct GifAppState {
    var image: UIImage?

    enum Message {
        case reload
        case receiveMetaData(Data?)
        case receiveImageData(Data?)
    }

    enum Output {
        case load(URL, onComplete: (Data?) -> Message)
    }

    mutating func send(_ message: Message) -> Output? {
        switch message {
        case .reload:
            return .load(randomGifURL(), onComplete: Message.receiveMetaData)
        case .receiveMetaData(let data):
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dict = json as? [String:Any],
                let dataDict = dict["data"] as? [String:Any],
                let imageURLString = dataDict["image_url"] as? String,
                let url = URL(string: imageURLString) else {
                    return nil
            }
            return .load(url, onComplete: Message.receiveImageData)
        case .receiveImageData(let data):
            guard let data = data else { return nil }
            image = UIImage(data: data)
            return nil
        }
    }
}

extension GifAppState.Output {
    func interpret(_ callback: @escaping (GifAppState.Message) -> ()) {
        switch self {
        case let .load(url, onComplete: transform):
            URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
                DispatchQueue.main.async {
                    callback(transform(data))
                }
            }).resume()
        }
    }
}

class GifApp: UIViewController {
    let imageView = UIImageView()
    let button: UIButton = {
        let result = UIButton(type: .custom)
        result.setTitle("Reload", for: .normal)
        return result
    }()
    let stackView = UIStackView()

    var state: GifAppState = GifAppState(image: nil) {
        didSet {
            imageView.image = state.image
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        stackView.axis = .vertical
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(button)
        view.addSubview(stackView)

        button.addTarget(self, action: #selector(reload), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        stackView.frame = view.bounds
    }

    func send(message: GifAppState.Message) {
        state.send(message)?.interpret(self.send)
    }

    @objc func reload() {
        send(message: .reload)
    }
}

import PlaygroundSupport
PlaygroundPage.current.liveView = GifApp()
