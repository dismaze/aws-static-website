const { S3Client, ListObjectsV2Command, PutObjectCommand } = require('@aws-sdk/client-s3');

const s3 = new S3Client({ region: process.env.AWS_REGION || 'us-east-1' });

const BUCKET_NAME = process.env.BUCKET_NAME;
const GALLERY_PREFIX = process.env.GALLERY_PREFIX;

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event));

  try {
    const listCommand = new ListObjectsV2Command({
      Bucket: BUCKET_NAME,
      Prefix: GALLERY_PREFIX
    });

    const response = await s3.send(listCommand);
    const objects = response.Contents || [];

    const images = objects
      .filter(obj => 
        obj.Key !== `${GALLERY_PREFIX}manifest.json` &&
        /\.(webp|jpg|jpeg|png|gif)$/i.test(obj.Key)
      )
      .map(obj => ({
        name: obj.Key.split('/').pop(),
        path: obj.Key,
        size: obj.Size,
        modified: obj.LastModified.toISOString()
      }));

    const manifest = {
      images,
      generated: new Date().toISOString(),
      count: images.length
    };

    const putCommand = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: `${GALLERY_PREFIX}manifest.json`,
      Body: JSON.stringify(manifest, null, 2),
      ContentType: 'application/json'
    });

    await s3.send(putCommand);

    console.log('Manifest generated successfully');
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Manifest generated', imageCount: images.length })
    };
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};