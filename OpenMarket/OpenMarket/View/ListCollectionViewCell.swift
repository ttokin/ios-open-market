//  ListCollectionViewCell.swift
//  OpenMarket
//  Created by SummerCat on 2022/11/29.

import UIKit

final class ListCollectionViewCell: UICollectionViewCell {
    static let identifier: String = "listCell"
    var product: Product?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        productImageView.image = .none
        productNameLabel.text = .none
        priceLabel.attributedText = nil
        bargainPriceLabel.text = nil
        stockLabel.attributedText = nil
    }
    
    private let productImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5
        return imageView
    }()
    
    private let productNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .left
        return label
    }()
    
    private let stockLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.textAlignment = .right
        label.textColor = .gray
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    private let disclosureButton: UIButton = {
        let button = UIButton()
        let buttonImage = UIImage(systemName: "chevron.forward")
        button.setImage(buttonImage, for: .normal)
        button.tintColor = .gray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let stockLabelAndDisclosureButtonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let upperLineStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.textAlignment = .left
        label.textColor = .gray
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    private let bargainPriceLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textAlignment = .left
        label.textColor = .gray
        return label
    }()
    
    private let priceStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }()
    
    private let productDetailStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()
    
    private let cellStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 4
        return stack
    }()
    
    private func configureUI() {
        stockLabelAndDisclosureButtonStackView.addArrangedSubview(stockLabel)
        stockLabelAndDisclosureButtonStackView.addArrangedSubview(disclosureButton)
        
        upperLineStackView.addArrangedSubview(productNameLabel)
        upperLineStackView.addArrangedSubview(stockLabelAndDisclosureButtonStackView)
        
        priceStackView.addArrangedSubview(priceLabel)
        priceStackView.addArrangedSubview(bargainPriceLabel)
    
        productDetailStackView.addArrangedSubview(upperLineStackView)
        productDetailStackView.addArrangedSubview(priceStackView)
        
        cellStackView.addArrangedSubview(productImageView)
        cellStackView.addArrangedSubview(productDetailStackView)
        
        contentView.addSubview(cellStackView)
        
        NSLayoutConstraint.activate([
            cellStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cellStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 8),
            cellStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cellStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            productImageView.widthAnchor.constraint(equalTo: productImageView.heightAnchor),
            
            priceLabel.leadingAnchor.constraint(equalTo: priceStackView.leadingAnchor),
            priceLabel.trailingAnchor.constraint(lessThanOrEqualTo: priceStackView.trailingAnchor),
            priceLabel.widthAnchor.constraint(lessThanOrEqualTo: priceStackView.widthAnchor, multiplier: 0.5),
            
            disclosureButton.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.3),
            disclosureButton.widthAnchor.constraint(equalTo: disclosureButton.heightAnchor)
        ])
    }
    
    func updateContents(_ product: Product) {
        DispatchQueue.global().async {
            guard let url = URL(string: product.thumbnailURL),
                  let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                if product == self.product {
                    self.productImageView.image = image
                    self.productNameLabel.text = product.name
                    self.updatePriceLabel(product)
                    self.updateStockLabel(product)
                }
            }
        }
    }
    
    private func updatePriceLabel(_ product: Product) {
        priceLabel.attributedText = product.price.formatPrice(product.currency)
            .flatMap { NSAttributedString(string: $0) }
        
        bargainPriceLabel.attributedText = product.bargainPrice.formatPrice(product.currency)
            .flatMap { NSAttributedString(string: $0) }
        
        bargainPriceLabel.isHidden = product.price == product.bargainPrice

        if product.price != product.bargainPrice {
            priceLabel.attributedText = product.price.formatPrice(product.currency)?.invalidatePrice()
        }
    }
    
    private func updateStockLabel(_ product: Product) {
        guard product.stock > 0 else {
            stockLabel.attributedText = StockStatus.soldOut.rawValue.markSoldOut()
            return
        }
        
        if product.stock > 10000 {
            stockLabel.attributedText = NSAttributedString(string: StockStatus.enoughStock.rawValue)
            return
        }
        
        let remainingStock = StockStatus.remainingStock.rawValue + " : " + (Double(product.stock).formatToDecimal() ?? StockStatus.stockError.rawValue)
        
        stockLabel.attributedText = NSAttributedString(string: remainingStock)
    }
}


