
# OrderBook - Carnet d'ordres pour échanges de tokens

## Introduction

Ce contrat Solidity, `OrderBook`, implémente un carnet d'ordres pour échanger un token ERC20 (`tokenA`) contre de l'ETH. Les utilisateurs peuvent créer des ordres d'achat ou de vente, et lorsque des ordres compatibles sont trouvés, ils sont exécutés automatiquement. Le contrat conserve également un historique des ordres exécutés.

## Fonctionnement général

Le contrat gère deux types d'ordres :

- **Ordres d'achat** : Les utilisateurs souhaitent acheter une quantité de `tokenA` en échange d'ETH.
- **Ordres de vente** : Les utilisateurs souhaitent vendre une quantité de `tokenA` en échange d'ETH.

Les ordres sont stockés dans deux tableaux :

- `buyOrders[]` : contient les ordres d'achat.
- `sellOrders[]` : contient les ordres de vente.

Lorsque des ordres correspondants (matching) sont trouvés (c'est-à-dire des ordres ayant le même volume et le même prix), ils sont exécutés, et les tokens et ETH sont échangés entre les deux parties.

## Détails des fonctionnalités

### 1. **Structure des ordres**

Chaque ordre est défini par une structure `Order` qui contient les informations suivantes :

```solidity
struct Order {
    address user;    // Adresse de l'utilisateur qui a créé l'ordre
    uint256 volume;  // Volume du tokenA à acheter/vendre
    uint256 price;   // Prix proposé (en ETH)
}
```

Les ordres d'achat et de vente sont stockés dans deux tableaux distincts : `buyOrders` et `sellOrders`.

### 2. **Fonction `buy`**

Cette fonction permet à un utilisateur de créer un ordre d'achat. Si un ordre de vente correspondant existe dans le carnet, l'ordre est immédiatement exécuté.

```solidity
function buy(uint256 _volume, uint256 _price) public payable {
    require(msg.value == _price, "Incorrect ETH amount sent");
    // Vérification des ordres de vente correspondants et exécution
    // Ajout de l'ordre dans le carnet d'achat si aucun ordre correspondant n'est trouvé
}
```

- Si un ordre de vente correspondant est trouvé, le token `tokenA` est transféré à l'acheteur, et l'ETH est transféré au vendeur.
- Si aucun ordre ne correspond, l'ordre est ajouté dans le tableau `buyOrders`.

### 3. **Fonction `sell`**

Cette fonction permet à un utilisateur de créer un ordre de vente. Si un ordre d'achat correspondant existe dans le carnet, l'ordre est immédiatement exécuté.

```solidity
function sell(uint256 _volume, uint256 _price) public {
    require(tokenA.transferFrom(msg.sender, address(this), _volume), "Transfer of tokenA failed");
    // Vérification des ordres d'achat correspondants et exécution
    // Ajout de l'ordre dans le carnet de vente si aucun ordre correspondant n'est trouvé
}
```

- Si un ordre d'achat correspondant est trouvé, le token `tokenA` est transféré à l'acheteur, et l'ETH est transféré au vendeur.
- Si aucun ordre ne correspond, l'ordre est ajouté dans le tableau `sellOrders`.

### 4. **Gestion des ordres (Fonctions `removeBuyOrder` et `removeSellOrder`)**

Ces fonctions permettent de supprimer un ordre d'achat ou de vente après qu'il a été exécuté.

```solidity
function removeSellOrder(uint256 index) public {
    if (index != sellOrders.length - 1) {
        sellOrders[index] = sellOrders[sellOrders.length - 1];
    }
    sellOrders.pop();
}

function removeBuyOrder(uint256 index) public {
    if (index != buyOrders.length - 1) {
        buyOrders[index] = buyOrders[buyOrders.length - 1];
    }
    buyOrders.pop();
}
```

### 5. **Historique des ordres**

Lorsque deux ordres sont appariés, l'ordre exécuté est stocké dans le tableau `orderHistory`, ce qui permet de garder une trace des transactions effectuées.

```solidity
Order[] public orderHistory;
```

## Événements

Le contrat émet des événements pour signaler les actions importantes :

- **`NewBuyOrder`** : Émis lorsqu'un nouvel ordre d'achat est créé.
- **`NewSellOrder`** : Émis lorsqu'un nouvel ordre de vente est créé.
- **`OrderMatched`** : Émis lorsqu'un ordre d'achat et un ordre de vente sont appariés et exécutés.

Exemple d'événement `OrderMatched` :

```solidity
event OrderMatched(
    address indexed buyer,
    address indexed seller,
    uint256 volume,
    uint256 price
);
```

## Fonctionnement du matching des ordres

1. Lorsqu'un utilisateur souhaite acheter une certaine quantité de `tokenA`, il appelle la fonction `buy`, en envoyant la quantité d'ETH correspondante au prix proposé.
2. Le contrat parcourt les ordres de vente existants pour trouver un ordre correspondant (même volume et même prix). Si une correspondance est trouvée :
   - Le `tokenA` est transféré à l'acheteur.
   - L'ETH est transféré au vendeur.
   - L'ordre de vente est supprimé du carnet.
3. Si aucun ordre correspondant n'est trouvé, l'ordre est ajouté au carnet d'ordres d'achat.
4. Le processus est similaire pour la vente de `tokenA` via la fonction `sell`.

## Gestion des tokens

Le contrat prend en charge deux tokens ERC20, `tokenA` et `tokenB`, qui sont définis dans le constructeur. Cependant, dans la version actuelle du contrat, seules les transactions impliquant `tokenA` contre de l'ETH sont gérées.

## Conclusion

Le contrat `OrderBook` implémente un carnet d'ordres simple permettant de gérer des échanges entre le `tokenA` et de l'ETH. Il permet aux utilisateurs de créer et d'exécuter des ordres d'achat et de vente, avec des événements émis pour chaque opération importante, tout en conservant un historique des ordres exécutés.
