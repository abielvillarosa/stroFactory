# StrØ Factory Contract

This is the base contract for the decentralized application StrØ which aims to lessen the use of straws by incentivizing customers who opt out for straws.

### TestNet Deployment Details (Ropsten)

#### stroFactory.sol

   transaction hash:    0x41902270176a6695388ac4b576e7c06a8521f60bec370d40d4a55097307dacad<br>
   contract address:    0x8793cf9819146393fb2fd177dbfb99b5736cc860<br>
   block number:        6076061

#### Background

In 2015, a video of a turtle with a plastic straw is stuck into its nostrils went viral. Since the released of the clip, there are several campaigns on the prevention of the use of the plastic straws. Plastics, in general, kills up to 1 million sea birds, 100,000 sea mammals, marine turtles, and fishes each year  

Some of the countries have already implemented campaign towards non-use of plastic straws. In late 2018, several fastfood establishments and restaurants in Singapore has banned the use of plastic straw. But this effort has sparked backlash from some consumers who felt that they are inconvencienced.

To further this campaign and to entice consumers to say no to plastic straws especially when dining out, StrØ is a decentralized application to say “No to Straw.” This dApp will incentivize fastfood and restaurant customers, when they opt out from using plastic straws, with points which they can redeem to purchase for other food products on the catalogue for the restaurants / fast food where they earned their points.

#### Advance Contract applications
  - Factory Contract
  - State Channel
  - Signing and Verification
  
#### Functions

**newStro**
  - This deploys a new instance of the stro contract. New restaurants that want to participate in the campaign will be calling this   function

**newCustomerRedemptionChannelId**
  - This creates a new channel for every customer who want to participate on the campaign.

**stroStamping**
  - This will be called by the restaurant every time the customer opts out for straw. This will send amount to the payment channel which can be redeemed later
  
**stroRedeem**
  - This can be called either by the customer or the restaurant when customers wants to redeem $ points. In the dApp, this will be translated to the amount corresponding to the specific food product on the catalogue that the customer wants to redeem.
  
**disputeRedemption**
  - This enables either the customer/restaurant to dispute the redemption within the dispute period
  
**stroPay**
  - This will transfer the $ points to the customer account which can be used to redeemd for the food items.
    




 
