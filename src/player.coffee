# Down To The Felt
# Author: @mdp

exports.name = "Down To The Felt"
exports.owner = "@mdp <m@mdp.im>"

exports.play = (game) ->
  if game.state == 'complete'
    false
  else if game.state == 'pre-flop'
    call = false
    for card in game.self.cards
      if startingCards.indexOf(card) >= 0
        call = true
    if call
      game.betting.call
    else
      game.betting.call if game.betting.call < 50
  else
    hand = Hand.make game.community.concat(game.self.cards)
    if hand.rank >= 5
      game.self.chips
    if hand.rank >= 4
      game.self.chips * 0.5
    else if hand.rank >= 3
      game.betting.call
    else
      game.betting.call if game.betting.call < 100

startingCards = ["A", "K", "Q", "J"]

class Card
  constructor: (str) ->
    @value = str.substr(0,1)
    @suit = str.substr(1,1).toLowerCase()
    @rank = Card.VALUES.indexOf(@value)

  toString: ->
    if @rank == 0
      "A#{@suit}(Low)"
    else
      "#{@value}#{@suit}"

Card.VALUES=['1','2','3','4','5','6','7','8','9','T','J','Q','K','A']
Card.sort = (a,b) ->
  if a.rank > b.rank
    -1
  else if a.rank < b.rank
    1
  else
    0

class Hand
  # Need to take 7 cards, and return a best hand
  constructor: (cards) ->
    @cardPool = []
    @cards = []
    @suits = {}
    @values = []
    @cardPool = cards.map (c) ->
      if typeof c == 'string'
        new Card(c)
      else
        c
    @cardPool.sort(Card.sort)
    for card in @cardPool
      @suits[card.suit] ||= []
      @suits[card.suit].push card
      @values[card.rank] ||= []
      @values[card.rank].push card
    @values.reverse()
    @isPossible = @make()

  compare: (a) ->
    if @rank < a.rank
      return 1
    else if @rank > a.rank
      return -1
    result = 0
    for x in [0..4]
      if @cards[x].rank < a.cards[x].rank
        result = 1
        break
      else if @cards[x].rank > a.cards[x].rank
        result = -1
        break
    result

  beats: (h) ->
   result = @compare(h)
   if result < 0
     true
   else
     false

  losesTo: (h) ->
   result = @compare(h)
   if result > 0
     true
   else
     false

  ties: (h) ->
   result = @compare(h)
   if result == 0
     true
   else
     false

  nextHighest: (excluding) ->
    excluding ||= []
    excluding = excluding.concat @cards
    picks = @cardPool.filter (card) ->
      if excluding.indexOf(card) < 0
        true

    # Handle a generic high card compare
  make: ->
    # Override me

  toString: ->
    cards = @cards.map (c) ->
      c.toString()
    cards.join(",")


Hand.pickWinners = (hands) ->
  # Find highest ranked hands
  # reject any that lose another hand
  byRank = hands.map (h) -> h.rank
  highestRank = Math.max.apply(Math, byRank)
  hands = hands.filter (h) ->
    h.rank == highestRank
  hands = hands.filter (h) ->
    loses = false
    for hand in hands
      loses = h.losesTo(hand)
      break if loses
    !loses
  hands

Hand.make = (cards) ->
  # Build and return the best hand
  #
  hands = [StraightFlush, FourOfAKind, FullHouse, Flush, Straight,
    ThreeOfAKind, TwoPair, OnePair, HighCard]
  result = null
  for hand in hands
    result = new hand(cards)
    break if result.isPossible
  result

class StraightFlush extends Hand
  name: "Straight Flush"
  rank: 8
  make: ->
    possibleStraight = null
    for suit, cards of @suits
      if cards.length >= 5
        possibleStraight = cards
        break
    if possibleStraight
      straight = new Straight(possibleStraight)
      if straight.isPossible
        @cards = straight.cards
    @cards.length == 5

class FourOfAKind extends Hand
  name: "Four of a kind"
  rank: 7
  make: ->
    for cards in @values
      if cards && cards.length == 4
        @cards = cards
        @cards.push(@nextHighest()[0])
        break
    @cards.length == 5

class FullHouse extends Hand
  name: "Full house"
  rank: 6
  make: ->
    for cards in @values
      if cards && cards.length == 3
        @cards = cards
        break
    for cards in @values
      if cards && cards.length == 2
        @cards = @cards.concat cards
        break
    @cards.length == 5

class Flush extends Hand
  name: "Flush"
  make: ->
    for suit, cards of @suits
      if cards.length >= 5
        @cards = cards.slice(0,5)
        break
    @cards.length == 5
  rank: 5

class Straight extends Hand
  name: "Straight"
  make: ->
    for card in @cardPool
      # Handle a ace low straight
      if card.value == "A"
        @cardPool.push new Card("1#{card.suit}")
    for card in @cardPool
      previousCard = @cards[@cards.length-1]
      diff = null
      if previousCard
        diff = previousCard.rank - card.rank
      if diff > 1
        @cards = [] # Start over
        @cards.push(card)
      else if diff == 1
        @cards.push(card)
      #first time through the loop
      else if diff == null
        @cards.push(card)
      break if @cards.length == 5
    @cards.length == 5
  rank: 4

class ThreeOfAKind extends Hand
  name: "Three of a kind"
  rank: 3
  make: ->
    for cards in @values
      if cards && cards.length == 3
        @cards = cards
        @cards = @cards.concat(@nextHighest().slice(0,2))
        break
    @cards.length == 5

class TwoPair extends Hand
  name: "Two pair"
  rank: 2
  make: ->
    for cards in @values
      if @cards.length > 0 && cards && cards.length == 2
        @cards = @cards.concat cards
        @cards.push(@nextHighest()[0])
        break
      else if cards && cards.length == 2
        @cards = @cards.concat cards
    @cards.length == 5

class OnePair extends Hand
  name: "One pair"
  rank: 1
  make: ->
    for cards in @values
      if cards && cards.length == 2
        @cards = @cards.concat cards
        @cards = @cards.concat (@nextHighest().slice(0,3))
        break
    @cards.length == 5

class HighCard extends Hand
  name: "High card"
  rank: 0
  make: ->
    @cards = @cardPool.slice(0,5)
    true
