const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

const TABLE_NAME = process.env.NOTES_TABLE_NAME;

exports.handler = async (event) => {
  console.log('GET /notes - Request received');
  
  try {
    const params = {
      TableName: TABLE_NAME,
    };

    const result = await dynamodb.scan(params).promise();
    
    // Sort by timestamp descending (newest first)
    const notes = (result.Items || []).sort((a, b) => {
      const timeA = new Date(a.timestamp || a.createdAt).getTime();
      const timeB = new Date(b.timestamp || b.createdAt).getTime();
      return timeB - timeA;
    });

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
      },
      body: JSON.stringify({
        notes: notes,
        count: notes.length,
      }),
    };
  } catch (error) {
    console.error('Error fetching notes:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        error: 'Failed to fetch notes',
        message: error.message,
      }),
    };
  }
};

