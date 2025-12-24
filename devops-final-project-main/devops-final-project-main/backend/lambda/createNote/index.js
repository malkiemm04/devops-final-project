const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const crypto = require('crypto');

const TABLE_NAME = process.env.NOTES_TABLE_NAME;

exports.handler = async (event) => {
  console.log('POST /notes - Request received');
  
  try {
    const body = JSON.parse(event.body || '{}');
    const { title, content } = body;

    if (!title && !content) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({
          error: 'Title or content is required',
        }),
      };
    }

    const note = {
      id: crypto.randomUUID(),
      title: title || '',
      content: content || '',
      timestamp: new Date().toISOString(),
      createdAt: new Date().toISOString(),
    };

    const params = {
      TableName: TABLE_NAME,
      Item: note,
    };

    await dynamodb.put(params).promise();

    console.log('Note created successfully:', note.id);

    return {
      statusCode: 201,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
      },
      body: JSON.stringify(note),
    };
  } catch (error) {
    console.error('Error creating note:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        error: 'Failed to create note',
        message: error.message,
      }),
    };
  }
};

