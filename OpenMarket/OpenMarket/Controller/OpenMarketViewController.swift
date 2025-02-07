//
//  OpenMarket - OpenMarketViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit

final class OpenMarketViewController: UIViewController {
    private enum ProductListSection: Int {
        case main
    }
    
    private enum ViewType: Int {
        case list
        case grid
        
        var typeName: String {
            switch self {
            case .list:
                return "LIST"
            case .grid:
                return "GRID"
            }
        }
    }
    
    private enum LayoutConstants {
        case listCellContentInset
        case gridCellSectionInset
        case gridCellMinimumLineSpacing
        case gridCellMinimumInteritemSpacing
        case gridPerRow
        case gridPerCol
        
        var value: Double {
            switch self {
            case .listCellContentInset:
                return 5
            case .gridCellSectionInset:
                return 10
            case .gridCellMinimumLineSpacing:
                return 10
            case .gridCellMinimumInteritemSpacing:
                return 5
            case .gridPerRow:
                return 2
            case .gridPerCol:
                return 3
            }
        }
    }
    
    private var gridCollectionView: UICollectionView?
    private var listCollectionView: UICollectionView?
    private var segmentedControl: UISegmentedControl?
    private let activityIndicator = UIActivityIndicatorView()
    
    private var listDataSource: UICollectionViewDiffableDataSource<ProductListSection, Product.ID>?
    private var gridDataSource: UICollectionViewDiffableDataSource<ProductListSection, Product.ID>?
    private var products: [Product] = []
    private let networkManager = NetworkManager()
    private var pageNumber: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureListDataSource()
        
        fetchProductList(page: pageNumber)
    }
    
    private func configureUI() {
        configureNavigationBar()
        configureSegmentedControl()
        configureListCollectionView()
        configureActivityIndicator()
        view.bringSubviewToFront(activityIndicator)
    }
    
    private func configureNavigationBar() {
        navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(registerProduct(_:)))
    }
    
    private func configureSegmentedControl() {
        segmentedControl = UISegmentedControl(items: [])
        
        guard let segmentedControl = segmentedControl else { return }
        
        segmentedControl.insertSegment(withTitle: ViewType.list.typeName, at: segmentedControl.numberOfSegments, animated: true)
        segmentedControl.insertSegment(withTitle: ViewType.grid.typeName, at: segmentedControl.numberOfSegments, animated: true)
        
        segmentedControl.addTarget(self, action: #selector(self.segmentValueChanged(_:)), for: .valueChanged)
        
        segmentedControl.selectedSegmentIndex = ViewType.list.rawValue
        segmentValueChanged(segmentedControl)
        
        navigationItem.titleView = segmentedControl
    }
    
    @objc private func segmentValueChanged(_ sender: UISegmentedControl) {
        guard let viewType: ViewType = ViewType(rawValue: sender.selectedSegmentIndex) else { return }
        
        switch viewType {
        case ViewType.list:
            listCollectionView?.isHidden = false
            gridCollectionView?.isHidden = true
        case ViewType.grid:
            if gridCollectionView == nil {
                configureGridCollectionView()
                configureGridDataSource()
            }
            gridCollectionView?.isHidden = false
            listCollectionView?.isHidden = true
        }
    }
    
    @objc private func registerProduct(_ sender: UIBarButtonItem) {
        let productRegisterVC = ProductRegisterViewController()
        self.present(productRegisterVC, animated: true)
    }
    
    private func configureActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.style = .large
        activityIndicator.center = view.center
    }
    
    private func fetchProductList(page: Int) {
        activityIndicator.startAnimating()
        networkManager.fetchProductList(page) { result in
            switch result {
            case .success(let productList):
                self.filterProducts(productList.products)
                DispatchQueue.main.async {
                    self.applySnapshot(for: self.products)
                    self.activityIndicator.stopAnimating()
                }
            case .failure(let error):
                self.showDataRequestFailureAlert(error)
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    private func filterProducts(_ productList: [Product]) {
        for product in productList where !products.contains(product) {
            self.products.append(product)
        }
    }
    
    private func showDataRequestFailureAlert(_ error: NetworkError) {
        let alert = UIAlertController(title: AlertConstants.alertTitle.rawValue, message: error.description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AlertConstants.actionTitle.rawValue, style: .default))
        
        self.present(alert, animated: true)
    }
    
    private func configureListCollectionView() {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: LayoutConstants.listCellContentInset.value,
                                                     leading: LayoutConstants.listCellContentInset.value,
                                                     bottom: LayoutConstants.listCellContentInset.value,
                                                     trailing: LayoutConstants.listCellContentInset.value)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.07))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        listCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        guard let listCollectionView = listCollectionView else { return }
        
        configureCollectionView(listCollectionView)
    }
    
    private func configureListDataSource() {
        guard let listCollectionView = listCollectionView else { return }
        
        let cellRegistration = UICollectionView.CellRegistration<ListCollectionViewCell, Product> { cell, indexPath, product in
            cell.product = product
        }
        
        listDataSource = UICollectionViewDiffableDataSource<ProductListSection, Product.ID>(collectionView: listCollectionView) {
            colllectionView, indexPath, identifier -> UICollectionViewCell? in
            let product = self.findProduct(identifier)
            let cell = listCollectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: product)
            return cell
        }
    }
    
    private func findProduct(_ identifier: Product.ID) -> Product? {
        for product in products where product.id == identifier {
            return product
        }
        
        return nil
    }
    
    private func applySnapshot(for items: [Product]?) {
        var itemIdentifiers: [Product.ID] = []
        products.forEach {
            itemIdentifiers.append($0.id)
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<ProductListSection, Product.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(itemIdentifiers, toSection: .main)
        listDataSource?.apply(snapshot, animatingDifferences: false)
        gridDataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    private func configureGridCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = LayoutConstants.gridCellMinimumLineSpacing.value
        layout.minimumInteritemSpacing = LayoutConstants.gridCellMinimumInteritemSpacing.value
        layout.sectionInset = UIEdgeInsets(top: LayoutConstants.gridCellSectionInset.value,
                                           left: LayoutConstants.gridCellSectionInset.value,
                                           bottom: LayoutConstants.gridCellSectionInset.value,
                                           right: LayoutConstants.gridCellSectionInset.value)
        gridCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        guard let gridCollectionView = gridCollectionView else { return }
        
        configureCollectionView(gridCollectionView)
    }
    
    private func configureCollectionView(_ collectionView: UICollectionView) {
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
    
    private func configureGridDataSource() {
        guard let gridCollectionView = gridCollectionView else { return }
        
        gridCollectionView.register(GridCollectionViewCell.self, forCellWithReuseIdentifier: GridCollectionViewCell.identifier)
        
        gridDataSource = UICollectionViewDiffableDataSource<ProductListSection, Product.ID>(collectionView: gridCollectionView) {
            collectionView, indexPath, identifier -> UICollectionViewCell? in
            let product = self.findProduct(identifier)
            guard let product else { return UICollectionViewCell() }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GridCollectionViewCell.identifier, for: indexPath) as? GridCollectionViewCell
            cell?.product = product
            return cell
        }
    }
}

extension OpenMarketViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == products.count - 1 {
            pageNumber += 1
            fetchProductList(page: pageNumber)
        }
    }
}

extension OpenMarketViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = (collectionView.frame.width / LayoutConstants.gridPerRow.value)
        - (LayoutConstants.gridCellMinimumInteritemSpacing.value * (LayoutConstants.gridPerRow.value + 1))
        let height: CGFloat = (collectionView.frame.height / LayoutConstants.gridPerCol.value)
        - (LayoutConstants.gridCellMinimumInteritemSpacing.value * (LayoutConstants.gridPerCol.value + 1))
        return CGSize(width: width, height: height)
    }
}
