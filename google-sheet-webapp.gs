function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Votes");
    if (!sheet) sheet = SpreadsheetApp.getActiveSpreadsheet().insertSheet("Votes");
    var positions = data.positions || [];
    for (var i = 0; i < positions.length; i++) {
      var p = positions[i];
      sheet.appendRow([
        data.voterId || "",
        data.voterName || "",
        p.position || "",
        p.candidate || (p.isAbstain ? "Abstain" : ""),
        p.isAbstain ? "Yes" : "No",
        data.ballotId || "",
        data.castAt || new Date().toISOString()
      ]);
    }
    return ContentService.createTextOutput(JSON.stringify({ ok: true })).setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({ error: err.message })).setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet(e) {
  return ContentService.createTextOutput(JSON.stringify({ status: "ok", sheets: "ready" })).setMimeType(ContentService.MimeType.JSON);
}