const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

const TABLE_NAME = process.env.NOTES_TABLE_NAME;

exports.handler = async (event) => {
  console.log('DELETE /notes/{id} - Request received');
  
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

    // Delete note
    const deleteParams = {
      TableName: TABLE_NAME,
      Key: {
        id: noteId,
      },
    };

    await dynamodb.delete(deleteParams).promise();

    console.log('Note deleted successfully:', noteId);

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
      },
      body: JSON.stringify({
        message: 'Note deleted successfully',
        id: noteId,
      }),
    };
  } catch (error) {
    console.error('Error deleting note:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        error: 'Failed to delete note',
        message: error.message,
      }),
    };
  }
};

