#! /bin/bash

# target web
web='https://www.passiton.com/inspirational-quotes'

# random (1-50) number for pagination
page=$(shuf -i 1-50 -n 1)

# magic! (filter web elements to get a quote)
quote=$(curl -s $web?page=$page | grep "<img alt=" | tr -s ">" | cut -f2 -d ">" | cut -f1 -d "#" | cut -f2 -d '"' | grep -v "&" | shuf -n 1)

echo -e "\n    $quote"

# Made by Manuel Romero - mrm8488@gmail.com
# #!/bin/bash
#
# # URL of Goodreads quotes page
# URL="https://www.goodreads.com/quotes"
#
# # Get a random quote from the page
# QUOTE=$(curl -s "$URL" | grep -oP '(?<=<div class="quoteText">).*?(?=</div>)' | shuf -n 1)
#
# # Clean up the quote to make it more readable
# QUOTE=$(echo $QUOTE | sed -e 's/<[^>]*>//g' | sed -e 's/&nbsp;//g' | sed -e 's/â€™/'\''/g')
#
# # Print the quote
# echo "$QUOTE"
