#!/data/data/com.termux/files/usr/bin/bash
# Replace with your bot's token
BOT_TOKEN="${1:?no bot}"
# Replace with the chat ID you want to send the message to
CHAT_ID="${2:?no chat id}"
# Replace with the path to your PDF file
PDF_FILE="${3:?no pdf}"
#PDF_FILE=$(echo "${PDF_FILE}" | sed 's/"/\\"/g')

# Set the message caption (optional)
CAPTION="${4}"
#CAPTION=$(echo "${CAPTION}" | sed 's/"/\\"/g')

# Set the webhook URL
URL="https://api.telegram.org/bot${BOT_TOKEN}/sendDocument"


# Send the request using cURL
if [[ -n "$CAPTION}" ]]
then
  curl -F "chat_id=${CHAT_ID}" -F "document=@${PDF_FILE}" -F "caption=${CAPTION}" "${URL}"
else
  curl -F "chat_id=${CHAT_ID}" -F "document=@${PDF_FILE}" "${URL}"
fi
