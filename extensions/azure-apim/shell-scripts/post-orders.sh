i=1
while [ $i -le 100 ]
do
curl -k -i -X POST -H "Content-Type:application/json" -H "Ocp-Apim-Trace:true" -H "Ocp-Apim-Subscription-Key:ababxxxyyyyzzzz" -d "{ \"item\" : \"Colombia\", \"price\" : 28.75, \"quantity\" : 80, \"description\" : \"Medium Roast Ethiopian\", \"cname\" : \"Acme Corporation\", \"dcode\" : \"8%\", \"origin\" : \"SAP\"}" https://xyz.azure-api.net/bcc/orders
i=$[$i+1]
echo "-----------------------------------------------"
# sleep 1
done
