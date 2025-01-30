#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Ask for username
echo "Enter your username:"
read USERNAME

# Check if user exists
EXISTING_USER=$($PSQL "select username from users where username='$USERNAME';")
if [[ -z $EXISTING_USER ]]
then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert user into the users table
  QUERY_RESULT=$( $PSQL "insert into users (username, games_played, best_game) values ('$USERNAME', 0, 1000)" )
else
  # Returning user
  USER_ID=$($PSQL "select user_id from users where username='$USERNAME';")
  
  # Fetch games played and best game guess count
  GAMES_COUNT=$($PSQL "select games_played from users where user_id='$USER_ID';")
  BEST_GAME_GUESS_COUNT=$($PSQL "select best_game from users where user_id='$USER_ID';")

  # Print welcome back message
  echo "Welcome back, $USERNAME! You have played $GAMES_COUNT games, and your best game took $BEST_GAME_GUESS_COUNT guesses."
fi

# Generate secret number
GUESS_COUNT=0
RANDOM_NUMBER=$(( RANDOM % 1000 + 1 ))

# Ask user to guess the number
echo "Guess the secret number between 1 and 1000:"
read NUMBER_GUESSED

# Main loop for guessing
while [ $RANDOM_NUMBER != $NUMBER_GUESSED ]
do
  if [[ ! $NUMBER_GUESSED =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  else
    (( GUESS_COUNT++ ))
    if [[ $NUMBER_GUESSED -gt $RANDOM_NUMBER ]]
    then
      echo "It's lower than that, guess again:"
    elif [[ $NUMBER_GUESSED -lt $RANDOM_NUMBER ]]
    then
      echo "It's higher than that, guess again:"
    fi
  fi
  read NUMBER_GUESSED
done

# Increment guess count for the last guess
(( GUESS_COUNT++ ))

# Insert the game result into won_user_games table
USER_ID=$($PSQL "select user_id from users where username='$USERNAME';")
QUERY_RESULT=$($PSQL "insert into won_user_games (user_id, guess_count) values ('$USER_ID', $GUESS_COUNT);")

# Update the games played and best game in the users table
# Increment games played
QUERY_RESULT=$($PSQL "update users set games_played = games_played + 1 where username='$USERNAME';")
# Update best game guess count
QUERY_RESULT=$($PSQL "update users set best_game = LEAST(best_game, $GUESS_COUNT) where username='$USERNAME';")

# Finish the game
echo "You guessed it in $GUESS_COUNT tries. The secret number was $RANDOM_NUMBER. Nice job!"
