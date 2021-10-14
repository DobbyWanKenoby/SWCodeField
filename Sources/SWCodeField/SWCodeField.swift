import UIKit

/**
 SWCodeField - класс, обеспечивающий работу графического элемента "Поле для ввода кода"
 */

@IBDesignable
open class SWCodeField: UIStackView {
    
    // MARK: API
    
    /// Выполняется после того, как заполняются все текстовые поля
    // Принимает code в качестве входного значения
    public var doAfterCodeDidEnter: ((String) -> Void)?
    /// Код в текстовых полях
    public var code: String {
        get {
            enteredCode.map { String($0) }.joined()
        }
        set {
            for (index, symbol) in newValue.enumerated() {
                textFields[index].value?.text = "\(symbol)"
            }
        }
    }
    
    // MARK: Properties
    
    // количество блоков с текстовыми полями
    @IBInspectable
    private var blocks: Int = 0 {
        didSet {
            createBlocks()
        }
    }
    // количество текстовых полей в каждом блоке
    @IBInspectable
    private var elementsInBlock: Int = 0 {
        didSet {
            createBlocks()
        }
    }
    
    private var enteredCode: [Int] {
        var resultNumbers = [Int]()
        textFields.forEach { textField in
            if let text = textField.value?.text, let number = Int(text) {
                resultNumbers.append(number)
            }
        }
        return resultNumbers
    }
    
    // Wrapper для хранения слабых ссылок на текстовые поля
    class TFWrapper {
        weak var value: UITextField?
        init(_ tf: UITextField) {
            value = tf
        }
    }
    
    private var textFields: [TFWrapper] = []
    
    convenience public init(blocks: Int, elementsInBlock: Int) {
        
        guard blocks > 0, elementsInBlock > 0 else {
            fatalError("SWCodeField: Blocks and elements count must more than 0")
        }
        
        self.init(frame: .zero)
        
        self.blocks = blocks
        self.elementsInBlock = elementsInBlock
        
        createBlocks()
        configureMainStackView()
    }
    
    // Создание блоков, включая вложенные элементы
    private func createBlocks() {
        guard blocks > 0, elementsInBlock > 0 else {
            return
        }
        
        removeArrangedViews()
        textFields.removeAll()
        
        // создание блоков
        (1...blocks).forEach { _ in
            let block = getBlockStackView()
            // создание элементов внутри блока
            (1...elementsInBlock).forEach { elementIndex in
                // текстовое поле
                let textField = getTextField()
                textFields.append(TFWrapper(textField))

                // stack для объединения поля и линии
                let stackView = UIStackView(arrangedSubviews: [textField, getBottomLine()])
                stackView.distribution = .fill
                stackView.axis = .vertical
                stackView.spacing = 2

                block.addArrangedSubview(stackView)
            }
            self.addArrangedSubview(block)
        }
    }
    
    private func removeArrangedViews() {
        for view in arrangedSubviews {
            view.removeFromSuperview()
        }
    }
    
    // Конфигурирование основного StackView
    private func configureMainStackView() {
        self.axis = .horizontal
        self.spacing = 20
        self.distribution = .fillEqually
    }
    
    // Внутренний StackView, объединяющий текстовое поле и линию под ним
    private func getBlockStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.spacing = 5
        stackView.axis = self.axis
        stackView.distribution = .fillEqually
        return stackView
    }
    
    // Текстовое поле, в которое вводится число
    private func getTextField() -> UITextField {
        let textField = SWCodeTextField()
        // обработчик нажатия на кнопку удаления символа
        textField.onDeleteBackward = {
            self.removeLastNumber()
            let lastFieldIndex = self.enteredCode.count
            self.textFields[lastFieldIndex].value?.becomeFirstResponder()
        }
        textField.keyboardType = .numberPad
        textField.addAction(getActionFor(textField: textField), for: .editingChanged)
        textField.textAlignment = .center
        textField.font = .systemFont(ofSize: 30)
        textField.delegate = self
        return textField
    }
    
    // действие для текстового поля
    private func getActionFor(textField: UITextField) -> UIAction {
        let action = UIAction { action in
            guard let text = textField.text, let _ = Int(text) else {
                return
            }
            let lastFieldIndex = self.enteredCode.count
            if lastFieldIndex < self.textFields.count && lastFieldIndex > 0  {
                self.textFields[lastFieldIndex].value?.becomeFirstResponder()
            } else {
                self.textFields.last?.value?.resignFirstResponder()
                self.doAfterCodeDidEnter?(self.code)
            }
        }
        return action
    }
    
    // Линия под текстовым полем
    private func getBottomLine() -> UIView {
        let view = UIView()
        view.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 3))
        view.backgroundColor = UIColor.lightGray
        view.layer.cornerRadius = 3
        return view
    }
    
    // MARK: Helpers
    
    // Удаляет символ из последнего заполненного текстового поля
    private func removeLastNumber() {
        for textField in textFields.reversed() {
            if let text = textField.value?.text, text != "" {
                textField.value!.text =  ""
                return
            }
        }
    }
    
    // Активирует первое незаполненное текстовое поле
    // В случае, когда заполнены все поля, то активирует последнее
    private func activateCorrectTextField() {
        let lastFieldIndex = self.enteredCode.count
        if lastFieldIndex == textFields.count {
            self.textFields.last?.value?.becomeFirstResponder()
        } else if lastFieldIndex == 0 {
            self.textFields.first?.value?.becomeFirstResponder()
        } else {
            self.textFields[lastFieldIndex].value?.becomeFirstResponder()
        }
    }

}

extension SWCodeField: UITextFieldDelegate {
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        activateCorrectTextField()
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Если текст вставляется, например из пришедшей СМС
        if string.count > 1 {
            // TODO: Добавить обработку вставки текста
            return true
        // Если текст вводится
        } else {
            // Ограничение на количество вводимых символов
            let maxLength = 1
            let currentString: NSString = (textField.text ?? "") as NSString
            let newString: NSString =
                currentString.replacingCharacters(in: range, with: string) as NSString
            return newString.length <= maxLength
        }
    }
    
}

// Кастомный класс текстового поля с переопределенным поведением по нажатию на бэкспейс
fileprivate class SWCodeTextField: UITextField {
    
    var onDeleteBackward: (() -> Void)?
    
    override public func deleteBackward() {
        onDeleteBackward?()
        super.deleteBackward()
    }
}
