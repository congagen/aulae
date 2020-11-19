// Source
var source_name = document.getElementById("source_name");
var source_id = document.getElementById("source_id");
var source_description = document.getElementById("source_description");

// Content
var item_name = document.getElementById("item_name");
var item_info = document.getElementById("item_info");
var item_type = document.getElementById("item_type");

var item_text = document.getElementById("item_text");
var item_text_color = document.getElementById("item_text_color");

var item_url = document.getElementById("item_url");
var item_link_url = document.getElementById("item_link_url");

var item_scale = document.getElementById("item_scale");
var world_scale = document.getElementById("world_scale");
var world_position = document.getElementById("world_position");

var billboard = document.getElementById("billboard");

var latitude = document.getElementById("latitude");
var longitude = document.getElementById("longitude");

var xPos = document.getElementById("x_pos");
var yPos = document.getElementById("y_pos");
var zPos = document.getElementById("z_pos");

var encircle = document.getElementById("circle");

function uuidv4() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

function getSourceData() {
    spec_data = {};

    spec_data["name"] = source_name.value;
    spec_data["id"] = uuidv4();
    spec_data["info"] = source_description.value;
    spec_data["version"] = parseInt((Math.random() * 10000000000));
    spec_data["updated_utx"] = parseFloat(Date.now());
    spec_data["content"] = {};

    if (encircle) {
        var i;
        var pos = [[2,0], [-2,0], [0,2], [0,-2]];

        for (i = 0; i < 4; i++) {
            let itmn = item_name.value + "_" + i.toString();
            spec_data["content"][itmn] = {};

            spec_data["content"][itmn]["name"] = item_name.value;
            spec_data["content"][itmn]["info"] = item_info.value;
            spec_data["content"][itmn]["type"] = item_type.value;

            spec_data["content"][itmn]["url"] = item_url.value;
            spec_data["content"][itmn]["content_link"] = item_link_url.value;

            spec_data["content"][itmn]["text"] = item_text.value;
            spec_data["content"][itmn]["hex_color"] = item_text_color.value;

            spec_data["content"][itmn]["scale"] = parseFloat(item_scale.value);
            spec_data["content"][itmn]["world_scale"] = world_scale.checked;
            spec_data["content"][itmn]["billboard"] = billboard.checked;
            spec_data["content"][itmn]["world_position"] = world_position.checked;

            spec_data["content"][itmn]["lat"] = parseFloat(latitude.value);
            spec_data["content"][itmn]["lng"] = parseFloat(longitude.value);

            spec_data["content"][itmn]["x_pos"] = parseFloat(xPos.value) + pos[i][0];
            spec_data["content"][itmn]["y_pos"] = parseFloat(xPos.value);
            spec_data["content"][itmn]["z_pos"] = parseFloat(zPos.value) + pos[i][1];
        }
    } else {
        spec_data["content"] = {};
        spec_data["content"][item_name.value] = {};

        spec_data["content"][item_name.value]["name"] = item_name.value;
        spec_data["content"][item_name.value]["info"] = item_info.value;
        spec_data["content"][item_name.value]["type"] = item_type.value;

        spec_data["content"][item_name.value]["url"] = item_url.value;
        spec_data["content"][item_name.value]["content_link"] = item_link_url.value;

        spec_data["content"][item_name.value]["text"] = item_text.value;
        spec_data["content"][item_name.value]["hex_color"] = item_text_color.value;

        spec_data["content"][item_name.value]["scale"] = parseFloat(item_scale.value);
        spec_data["content"][item_name.value]["world_scale"] = world_scale.checked;
        spec_data["content"][item_name.value]["billboard"] = billboard.checked;
        spec_data["content"][item_name.value]["world_position"] = world_position.checked;

        spec_data["content"][item_name.value]["lat"] = parseFloat(latitude.value);
        spec_data["content"][item_name.value]["lng"] = parseFloat(longitude.value);

        spec_data["content"][item_name.value]["x_pos"] = parseFloat(xPos.value);
        spec_data["content"][item_name.value]["y_pos"] = parseFloat(yPos.value);
        spec_data["content"][item_name.value]["z_pos"] = parseFloat(zPos.value);
    }

    console.log(spec_data);
    return spec_data;
}

function saveJson(spec) {
    var jsonse = JSON.stringify(spec, null, 4);
    var blob = new Blob([jsonse], {type: "application/json"});
    var anchor = document.createElement("a");
    anchor.download = "source.json";
    anchor.href = window.URL.createObjectURL(blob);
    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
}

genBtn.onclick = function() {
    spec = getSourceData();
    saveJson(spec);
}
