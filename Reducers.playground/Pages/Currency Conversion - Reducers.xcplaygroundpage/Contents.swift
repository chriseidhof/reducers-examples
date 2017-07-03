//: Playground - noun: a place where people can play

import UIKit

enum Currency: String {
    case eur = "EUR"
    case usd = "USD"
}

func ratesURL(base: Currency = .eur) -> URL {
    return URL(string: "http://api.fixer.io/latest?base=\(base.rawValue)")!
}

struct State {
    private var inputAmount: Double? = nil
    private var rate: Double? = nil
    var output: Double? {
        guard let i = inputAmount, let r = rate else { return nil }
        return i * r
    }

    enum Message {
        case inputChanged(String?)
        case reload
        case ratesAvailable(data: Data?)
    }

    enum Command {
        case load(URL, onComplete: (Data?) -> Message)
    }

    mutating func send(_ message: Message) -> Command? {
        switch message {
        case .inputChanged(let input):
            inputAmount = input.flatMap { Double($0) }
            return nil
        case .reload:
            return .load(ratesURL(), onComplete: Message.ratesAvailable)
        case .ratesAvailable(data: let data):
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dict = json as? [String:Any],
                let dataDict = dict["rates"] as? [String:Double],
                let rate = dataDict[Currency.usd.rawValue] else { return nil }
            self.rate = rate
            return nil
        }
    }
}

extension State.Command {
    func interpret(_ callback: @escaping (State.Message) -> ()) {
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

class CurrencyApp: UIViewController {
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
    
    var state = State() {
        didSet {
            self.output.text = state.output.map { "\($0) USD" } ?? ""
        }
    }
    
    private func send(_ message: State.Message) {
        state.send(message)?.interpret(self.send)
    }
    
    @objc func inputChanged() {
        send(.inputChanged(input.text))
    }

    @objc func reload() {
        send(State.Message.reload)
    }

}

import PlaygroundSupport
PlaygroundPage.current.liveView = CurrencyApp()
