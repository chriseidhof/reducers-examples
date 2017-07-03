//: Playground - noun: a place where people can play

import UIKit

func randomGifURL(tag: String? = nil) -> URL {
    return URL(string: "http://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC")!
}

class GifApp: UIViewController {
    let imageView = UIImageView()
    let button: UIButton = {
        let result = UIButton(type: .custom)
        result.setTitle("Reload", for: .normal)
        return result
    }()
    let stackView = UIStackView()

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


    @objc func reload() {
        URLSession.shared.dataTask(with: randomGifURL()) { (data, _, _) in
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dict = json as? [String:Any],
                let dataDict = dict["data"] as? [String:Any],
                let imageURLString = dataDict["image_url"] as? String,
                let url = URL(string: imageURLString)
            else {
                return
            }

            URLSession.shared.dataTask(with: url) { (data, _, _) in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.imageView.image = image
                }

            }.resume()

        }.resume()
    }

}

import PlaygroundSupport
PlaygroundPage.current.liveView = GifApp()
