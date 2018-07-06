//
//  BTCUtil
//
//  Created by Otto Suess on 10.04.18.
//  Copyright © 2018 Zap. All rights reserved.
//

import Foundation

private extension URLComponents {
    func queryItem(name: String) -> String? {
        return queryItems?.first(where: { $0.name == name })?.value
    }
}

public struct BitcoinURI: PaymentURI {
    public let address: String
    public let amount: Satoshi?
    public let memo: String?
    public let network: Network
    
    public var stringValue: String {
        var urlComponents = URLComponents(string: "bitcoin:\(address)")
        var queryItems = [URLQueryItem]()
        
        if let amount = amount, amount > 0 {
            queryItems.append(URLQueryItem(name: "amount", value: amount.convert(to: .bitcoin).stringValue))
        }
        if let memo = memo, !memo.isEmpty {
            queryItems.append(URLQueryItem(name: "message", value: memo))
        }
        if !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems
        }
        
        return urlComponents?.string ?? "bitcoin:\(address)"
    }
    
    public init?(string: String) {
        guard let components = URLComponents(string: string) else { return nil }

        let amount: Satoshi?
        if let amountString = components.queryItem(name: "amount") {
            amount = Satoshi.from(string: amountString, unit: .bitcoin)
        } else {
            amount = nil
        }
        
        let memo = components.queryItem(name: "message")
        
        self.init(address: components.path, amount: amount, memo: memo)
    }
    
    public init?(address: String, amount: Satoshi? = nil, memo: String? = nil) {
        if let (humanReadablePart, _) = Bech32.decode(address) {
            if humanReadablePart.lowercased() == "tb" {
                network = .testnet
            } else if humanReadablePart.lowercased() == "bc" {
                network = .mainnet
            } else {
                return nil
            }
        } else if let bitcoinAddress = BitcoinAddress(string: address),
            bitcoinAddress.type != .privateKey {
            self.network = bitcoinAddress.network
        } else {
            return nil
        }
        
        self.address = address
        self.amount = amount
        self.memo = memo
    }
}
