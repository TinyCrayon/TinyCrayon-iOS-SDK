AWS.config.update({
    region: "us-east-1"
});

AWS.config.credentials = new AWS.CognitoIdentityCredentials({
    IdentityPoolId: "us-east-1:21e1e544-6c11-4b05-815c-1493f363d2fa",
    RoleArn: "arn:aws:iam::358518170177:role/Cognito_logUnauth_Role"
});

var dynamodb = new AWS.DynamoDB();
var docClient = new AWS.DynamoDB.DocumentClient();

var params = {
    TableName : "TCMaskiOSLog"
};

var globalData;

docClient.scan(params, function(err, data) {
    if (err) {
	$('#sdk-log-content .message').removeClass('hidden');
	$('#sdk-log-content .message').text(err);
	$('#sdk-log-content .table').addClass('hidden');
	console.log(err)
    }
    else {
	var tbody = $('#sdk-log-content table tbody');
	for (var i = 0; i < data.Count; i++) {
	    var tr = $('<tr></tr>');
	    var item = data.Items[i];
	    tr.append($('<td></td>').text(i + 1));
	    tr.append($('<td></td>').text(item.bundleID));
	    tr.append($('<td></td>').text(item.date));
	    tr.append($('<td></td>').text(item.system));
	    tbody.append(tr);
	}
    }
});

params = {
    TableName : "AndroidSubscription",
}

docClient.scan(params, function(err, data) {
    if (err) {
	$('#android-subscription-content .message').removeClass('hidden');
	$('#android-subscription-content .message').text(err);
	$('#android-subscription-content .table').addClass('hidden');
	console.log(err)
    }
    else {
	var tbody = $('#android-subscription-content table tbody');
	for (var i = 0; i < data.Count; i++) {
	    var tr = $('<tr></tr>');
	    var item = data.Items[i];
	    tr.append($('<td></td>').text(i + 1));
	    tr.append($('<td></td>').text(item.email));
	    tbody.append(tr);
	}
    }
});
