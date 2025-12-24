const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

const TABLE_NAME = process.env.NOTES_TABLE_NAME;

exports.handler = async (event) => {
  console.log('PUT /notes/{id} - Request received');
  
  const noteId = event.pathParameters?.id;
  
  if (!noteId) {
    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        error: 'Note ID is required',
      }),
    };
  }

  try {
    const body = JSON.parse(event.body || '{}');
    const { title, content } = body;

    // First, check if note exists
    const getParams = {
      TableName: TABLE_NAME,
      Key: {
        id: noteId,
      },
    };

    const existingNote = await dynamodb.get(getParams).promise();

    if (!existingNote.Item) {
      return {
        statusCode: 404,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({
          error: 'Note not found',
        }),
      };
    }

    // Update note
    const updateParams = {
      TableName: TABLE_NAME,
      Key: {
        id: noteId,
      },
      UpdateExpression: 'SET #title = :title, #content = :content, updatedAt = :updatedAt',
      ExpressionAttributeNames: {
        '#title': 'title',
        '#content': 'content',
      },
      ExpressionAttributeValues: {
        ':title': title !== undefined ? title : existingNote.Item.title,
        ':content': content !== undefined ? content : existingNote.Item.content,
        ':updatedAt': new Date().toISOString(),
      },
      ReturnValues: 'ALL_NEW',
    };

    const result = await dynamodb.update(updateParams).promise();

    console.log('Note updated successfully:', noteId);

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
      },
      body: JSON.stringify(result.Attributes),
    };
  } catch (error) {
    console.error('Error updating note:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        error: 'Failed to update note',
        message: error.message,
      }),
    };
  }
};

