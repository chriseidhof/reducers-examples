//: Playground - noun: a place where people can play

import UIKit

enum Currency: String {
    case eur = "EUR"
    case usd = "USD"
}

func ratesURL(base: Currency = .eur) -> URL {
    return URL(string: "http://api.fixer.io/latest?base=\(base.rawValue)")!
}

class CurrencyApp: UIViewController, UITextFieldDelegate {
    let input: UITextField = {
        let result = UITextField()
        result.text = "100"
        result.borderStyle = .roundedRect
        return result
    }()
    let button: UIButton = {
        let result = UIButton(type: .custom)
        result.setTitle("Reload", for: .normal)
        return result
    }()
    let output: UILabel = {
        let result = UILabel()
        result.text = "..."
        return result
    }()
    let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        stackView.axis = .vertical
        stackView.addArrangedSubview(input)
        stackView.addArrangedSubview(button)
        stackView.addArrangedSubview(output)
        view.addSubview(stackView)

        button.addTarget(self, action: #selector(reload), for: .touchUpInside)
        input.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        stackView.frame = view.bounds
    }
    
    var rate: Double?
    @objc func inputChanged() {
        guard let rate = rate else { return }
        guard let text = input.text, let number = Double(text) else { return }
        output.text = "\(number * rate) USD"
    }
    
    @objc func reload() {
        URLSession.shared.dataTask(with: ratesURL()) { (data, _, _) in
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dict = json as? [String:Any],
                let dataDict = dict["rates"] as? [String:Double],
                let rate = dataDict[Currency.usd.rawValue] else { return }
            DispatchQueue.main.async { [weak self] in
                self?.rate = rate
                self?.inputChanged()
            }
        }.resume()
    }

}

import PlaygroundSupport
PlaygroundPage.current.liveView = CurrencyApp()
