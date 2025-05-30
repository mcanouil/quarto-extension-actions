#!/usr/bin/env bash

if [ -z "${QUARTO_PROJECT_RENDER_ALL}" ]; then
  exit 0
fi

HTML_FILES=$(echo "${QUARTO_PROJECT_OUTPUT_FILES}" | tr ' ' '\n' | grep -E '\.html$')

SLIDES_FILES=""
for HTML_FILE in ${HTML_FILES}; do
  if grep -q '<div class="reveal">' "${HTML_FILE}"; then
    SLIDES_FILES="${SLIDES_FILES} ${HTML_FILE}"
  fi
done

SLIDES_FILES=$(echo "${SLIDES_FILES}" | xargs)

for SLIDES_PATH in ${SLIDES_FILES}; do
  echo "Processing ${SLIDES_PATH}"
  
  PDF_AUTHOR=$(grep -o '<meta name="author" content="[^"]*"' "${SLIDES_PATH}" | sed 's/<meta name="author" content="\(.*\)"/\1/')
  PDF_TITLE=$(grep -o '<title>.*</title>' "${SLIDES_PATH}" | sed 's/<title>\(.*\)<\/title>/\1/')

  sed "s/el.parentElement.parentElement.parentElement;/el.parentElement.parentElement.parentElement.parentElement;/g;" "${SLIDES_PATH}" > "${SLIDES_PATH}.decktape.html"

  npx -y decktape reveal \
    --chrome-arg="--no-sandbox" \
    --chrome-arg="--disable-setuid-sandbox" \
    --size "1920x1080" \
    --screenshots \
    --screenshots-format png \
    --screenshots-directory . \
    --slides 1 \
    "${SLIDES_PATH}.decktape.html" index.pdf
  
  rm index.pdf
  mv index_1_1920x1080.png _site/poster.png
  
  npx -y decktape reveal \
    --chrome-arg="--no-sandbox" \
    --chrome-arg="--disable-setuid-sandbox" \
    --size "1920x1080" \
    --pause 2000 \
    --load-pause 2000 \
    --fragments \
    --pdf-author "${PDF_AUTHOR}" \
    --pdf-title "${PDF_TITLE}" \
    "${SLIDES_PATH}.decktape.html" "${SLIDES_PATH%.html}.pdf"

    mv "${SLIDES_PATH%.html}.pdf" $(basename $(dirname "${SLIDES_PATH%.html}.pdf"))/$(basename "$(pwd)").pdf

  rm "${SLIDES_PATH}.decktape.html"
done
