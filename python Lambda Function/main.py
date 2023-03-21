import json
import pandas as pd

def lambda_handler(event, context):
    # Parse incoming JSON payload
    try:
        data = json.loads(event['body'])
    except:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Invalid input'})
        }

    # Create Pandas DataFrame 
    df = pd.DataFrame(data)

    # Calculate average rating of movies
    avg_rating = df['rating'].mean()

    # Calculate the director who directed the most number of movies
    director_counts = df['director'].value_counts()
    top_director = director_counts.index[0]

    # Movies above the average rating
    movies_above_avg = df[df['rating'] > avg_rating].to_dict(orient='records')

    # Create response JSON
    response = {
        'average_rating': avg_rating,
        'director_with_most_movies': top_director,
        'movies_above_average_rating': movies_above_avg
    }

    # Return response
    return {
        'statusCode': 200,
        'body': json.dumps(response)
    }

