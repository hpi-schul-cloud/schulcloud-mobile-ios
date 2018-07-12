#!/bin/bash

set -x
rm -rf ${PROJECT_DIR}/iOS/Assets-ios-brand.generated.xcassets
cp -R ${PROJECT_DIR}/iOS/Branding/${PRODUCT_NAME}/Assets-ios-brand.xcassets ${PROJECT_DIR}/iOS/Assets-ios-brand.generated.xcassets
