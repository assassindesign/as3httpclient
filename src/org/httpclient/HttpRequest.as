/**
 * Copyright (c) 2007 Gabriel Handford
 * See LICENSE.txt for full license information.
 */
package org.httpclient {
  
  import com.adobe.net.URI;
  import com.adobe.net.URIEncodingBitmap;
  import com.hurlant.util.Base64;

  import flash.utils.ByteArray;
  import org.httpclient.http.multipart.Multipart;

  public class HttpRequest {
    
    public static const kUriPathEscapeBitmap:URIEncodingBitmap = new URIEncodingBitmap(" %:?#@");
    public static const kUriQueryEscapeBitmap:URIEncodingBitmap = new URIEncodingBitmap(" %");
    
    // Request method. For example, "GET"
    protected var _method:String;
    
    // Request header
    protected var _header:HttpHeader;
    
    // Request body
    protected var _body:*;
    
    /**
     * Create request.
     *  
     * The request body can be anything but should respond to:
     *  - readBytes(bytes:ByteArray, offset:uint, length:uint)
     *  - length
     *  - bytesAvailable
     *  - close
     *  
     * @param method
     * @param header
     * @param body 
     *  
     */
    public function HttpRequest(method:String, header:HttpHeader = null, body:* = null) {
      _method = method;
      _body = body;
      _header = header;
      
      // Create default header
      if (!_header) _header = new HttpHeader();
      
      loadDefaultHeaders();
    }
    
    /**
     * Include headers here that are global to every request.
     */
    protected function loadDefaultHeaders():void {
      addHeader("Connection", "close");      
      
      //addHeader("Accept-Encoding", "gzip, deflate");
      //addHeader("Accept-Language", "en-us");            
      //addHeader("User-Agent", "as3httpclientlib 0.1");
      //addHeader("Accept", "*/*");
    }
    
    /**
     * Add a header.
     * @param name
     * @param value
     */
    public function addHeader(name:String, value:String):void {
      _header.add(name, value);
    }
    
    // Abstract
    public function get hasRequestBody():Boolean {
      throw new Error("Must use a request subclass with this method defined.");
    }
    
    // Abstract
    public function get hasResponseBody():Boolean {
      throw new Error("Must use a request subclass with this method defined.");
    }
    
    public function get header():HttpHeader { return _header; }
    public function get method():String { return _method; }
    public function get body():* { return _body; }
    
    /**
     * The request body can be anything but should respond to:
     *  - readBytes(bytes:ByteArray, offset:uint, length:uint)
     *  - length
     *  - bytesAvailable
     *  - close
     */
    public function set body(body:*):void {
      _body = body;
      _header.replace("Content-Length", _body.length);
    }
    
    /**
     * Set content type.
     * @param contentType
     */
    public function set contentType(contentType:String):void {
      _header.replace("Content-Type", contentType);
    }
    
    /**
     * Set form data.
     * @param params Array of key value pairs: [ { name: "Foo", value: "Bar" }, { name: "Baz", value: "Bewm" },... ]
     * @param sep Separator 
     */
    public function setFormData(params:Array, sep:String = "&"):void {      
      _header.replace("Content-Type", "application/x-www-form-urlencoded");
      
      _body = new ByteArray();
      _body.writeUTFBytes(params.map(function(item:*, index:int, array:Array):String { 
          return encodeURI(item["name"]) + "=" + encodeURI(item["value"]); 
        }).join(sep));
        
      _body.position = 0;
      
      _header.replace("Content-Length", _body.length);
    }
    
    /**
     * Set multipart.
     */
    public function set multipart(multipart:Multipart):void {      
      _header.replace("Content-Type", "multipart/form-data; boundary=" + Multipart.BOUNDARY);
      _header.replace("Content-Length", String(multipart.length));      
      _body = multipart;
    }
    
    /**
     * Get header.
     */
    public function getHeader(uri:URI, proxy:URI = null, version:String = null):ByteArray {
      
      var bytes:ByteArray = new ByteArray();
      
      var path:String = uri.path;
      if (!path) path = "/";
      else path = URI.fastEscapeChars(path, kUriPathEscapeBitmap);
      
      if (uri.query) path += "?" + URI.fastEscapeChars(uri.query, kUriQueryEscapeBitmap);
      
      var host:String = uri.authority;
      if (uri.port) host += ":" + uri.port;
      
      if (!version) version = "1.1";
      
      if (proxy) {
        bytes.writeUTFBytes(method + " " + uri.toString() + " HTTP/" + version + "\r\n");
      } else {
        bytes.writeUTFBytes(method + " " + path + " HTTP/" + version + "\r\n");
      }
      bytes.writeUTFBytes("Host: " + host + "\r\n");
      
      if (proxy && proxy.username && proxy.password) {
        var credential:String = proxy.username + ":" + proxy.password;
        addHeader("Proxy-Authorization", "Basic " + Base64.encode(credential));
      }

      if (!header.isEmpty)
        bytes.writeUTFBytes(header.content);
        
      bytes.writeUTFBytes("\r\n");
      
      bytes.position = 0;
      return bytes;
    }
    
    
    public function toString():String {
      return "method: " + _method + ", header: " + _header + ", body: " + _body;
    }
        
  }
}