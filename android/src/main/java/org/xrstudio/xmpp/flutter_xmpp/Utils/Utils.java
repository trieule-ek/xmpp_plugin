// [The file has been modified by eKadence]

package org.xrstudio.xmpp.flutter_xmpp.Utils;

import android.content.Context;
import android.content.Intent;
import android.os.Environment;
import android.util.Log;

import org.jivesoftware.smack.packet.ExtensionElement;
import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smackx.forward.packet.Forwarded;
import org.jivesoftware.smackx.mam.element.MamElements;
import org.jivesoftware.smack.packet.StandardExtensionElement;
import org.jivesoftware.smack.util.PacketParserUtils;
import org.jivesoftware.smackx.chatstates.ChatState;
import org.jivesoftware.smackx.chatstates.packet.ChatStateExtension;
import org.jivesoftware.smackx.delay.packet.DelayInformation;
import org.jivesoftware.smackx.pubsub.EventElement;
import org.jivesoftware.smackx.pubsub.ItemsExtension;
import org.jivesoftware.smackx.pubsub.PayloadItem;
import org.jivesoftware.smackx.pubsub.SimplePayload;
import org.jivesoftware.smackx.receipts.DeliveryReceipt;
import org.jxmpp.jid.Jid;
import org.jxmpp.jid.impl.JidCreate;
import org.jxmpp.stringprep.XmppStringprepException;
import org.xrstudio.xmpp.flutter_xmpp.Connection.FlutterXmppConnection;
import org.xrstudio.xmpp.flutter_xmpp.Enum.ConnectionState;
import org.xrstudio.xmpp.flutter_xmpp.Enum.ErrorState;
import org.xrstudio.xmpp.flutter_xmpp.Enum.SuccessState;
import org.xrstudio.xmpp.flutter_xmpp.FlutterXmppPlugin;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class Utils {

    public static String logFilePath = "";
    static String logFileName = "xmpp_logs.txt";

    public static String getValidJid(String Jid) {

        if (Jid != null && Jid.contains(Constants.SYMBOL_COMPARE_JID)) {
            Jid = Jid.split(Constants.SYMBOL_COMPARE_JID)[0];
        }
        return Jid != null ? Jid : "";
    }

    public static Jid getFullJid(String Jid) {

        Jid fullJid = null;

        try {

            if (Jid != null && !Jid.contains(Constants.SYMBOL_COMPARE_JID)) {
                Jid = Jid + "@" + FlutterXmppConnection.mHost;
            }

            fullJid = JidCreate.from(Jid);
        } catch (XmppStringprepException e) {
            e.printStackTrace();
        }
        return fullJid;
    }

    public static long getLongDate() {
        return new Date().getTime();
    }

    public static String getJidWithDomainName(String jid, String host) {
        return jid.contains(host) ? jid : jid + Constants.SYMBOL_COMPARE_JID + host;
    }

    public static String getRoomIdWithDomainName(String groupName, String host) {
        String roomId = groupName;
        if (!groupName.contains(Constants.CONFERENCE)) {
            roomId = groupName + Constants.SYMBOL_COMPARE_JID + Constants.CONFERENCE + Constants.DOT + host;
        }
        return roomId;
    }

    public static void addLogInStorage(String text) {
        if (logFilePath == null || logFilePath.isEmpty()) {
            return;
        }
        text = "Time: " + getTimeMillisecondFormat() + " " + text;
        boolean fileExists = true;
//        checkDirectoryExist(logFilePath);
        try {
            File logFile = new File(logFilePath);

            if (!logFile.exists()) {
                try {
                    fileExists = logFile.createNewFile();
                } catch (IOException e) {
                    fileExists = false;
                    e.printStackTrace();
                }
            }
            if (fileExists) {
                try {
                    BufferedWriter buf = new BufferedWriter(new FileWriter(logFile, true));
                    buf.append(text.trim());
                    buf.append("\n");
                    buf.newLine();
                    buf.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void checkDirectoryExist(String directoryName) {
        File dir = new File(Environment.getExternalStorageDirectory(), directoryName);
        if (!dir.exists()) {
            dir.mkdirs();
        }
    }

    public static String getTimeMillisecondFormat() {
        return convertDate(new Date().getTime(), Constants.DATE_FORMAT);
    }

    public static String convertDate(long dateToConvert, String ddMmFormat) {
        Date date = new Date(dateToConvert);
        SimpleDateFormat df2 = new SimpleDateFormat(ddMmFormat, Locale.getDefault());
        return df2.format(date);
    }

    public static boolean validIP(String ip) {
        try {
            if (ip == null || ip.isEmpty()) {
                return false;
            }

            String[] parts = ip.split("\\.");
            if (parts.length != 4) {
                return false;
            }

            for (String s : parts) {
                int i = Integer.parseInt(s);
                if ((i < 0) || (i > 255)) {
                    return false;
                }
            }
            return !ip.endsWith(Constants.DOT);
        } catch (NumberFormatException nfe) {
            return false;
        }
    }

    public static void printLog(String message) {
        if (FlutterXmppPlugin.DEBUG) {
            Log.d(Constants.TAG, message);
        }
    }

    public static void broadcastMessageToFlutter(Context mApplicationContext, Message message) {

        Utils.addLogInStorage(" Action: receiveMessageFromServer, Content: " + message.toXML().toString());

        message = parseEventStanzaMessage(message);
        String META_TEXT = Constants.MESSAGE;
        String body = message.getBody();
        String from = message.getFrom().toString();
        String msgId = message.getStanzaId();
        String customText = "";

        StandardExtensionElement customElement = (StandardExtensionElement) message
                .getExtension(Constants.URN_XMPP_CUSTOM);
        if (customElement != null && customElement.getFirstElement(Constants.custom) != null) {
            customText = customElement.getFirstElement(Constants.custom).getText();
        }

        String time = Constants.ZERO;
        if (message.getExtension(Constants.URN_XMPP_TIME) != null) {
            StandardExtensionElement timeElement = (StandardExtensionElement) message
                    .getExtension(Constants.URN_XMPP_TIME);
            if (timeElement != null && timeElement.getFirstElement(Constants.TS) != null) {
                time = timeElement.getFirstElement(Constants.TS).getText();
            }
        }

        if (message.hasExtension(DeliveryReceipt.ELEMENT, DeliveryReceipt.NAMESPACE)) {
            DeliveryReceipt dr = DeliveryReceipt.from((Message) message);
            msgId = dr.getId();
            META_TEXT = Constants.DELIVERY_ACK;
        }

        ChatState chatState = null;

        if (message.hasExtension(ChatStateExtension.NAMESPACE)) {
            META_TEXT = Constants.CHATSTATE;
            ChatStateExtension chatStateExtension = (ChatStateExtension) message.getExtension(ChatStateExtension.NAMESPACE);
            chatState = chatStateExtension.getChatState();
        }

        String mediaURL = "";

        String delayTime = Constants.ZERO;
        if (message.hasExtension(Constants.URN_XMPP_RECEIPTS)) {
            DelayInformation DelayTimeElement = (DelayInformation) message.getExtension(Constants.URN_XMPP_DELAY);
            if (DelayTimeElement != null && DelayTimeElement.getStamp() != null) {
                delayTime = DelayTimeElement.getStamp().toString();
            }
        }

        String statusCode = "";
        MamElements.MamResultExtension mamResult = MamElements.MamResultExtension.from(message);
        if (mamResult != null)
        {
            Forwarded forwarded = mamResult.getForwarded();
            if (forwarded != null) {
                DelayInformation delayInfo = forwarded.getDelayInformation();
                if (delayInfo != null) {
                    delayTime = delayInfo.getStamp().toString();
                }

                Message fwdMessage = (Message) forwarded.getForwardedStanza();
                if (body == null) {
                    body = fwdMessage.getBody();
                    from = fwdMessage.getFrom().toString();
                }

                if (msgId == null) {
                    msgId = fwdMessage.getStanzaId();
                }

                statusCode = extractStatusCode(fwdMessage);
            }
        }
        
        String subject = extractSubject(message);

        List<String> urls = extractUrlsFromMessage(message);
        if (!urls.isEmpty()) {
            mediaURL = String.join(",", urls);
        }
        
        String mUser = FlutterXmppConnection.mUsername;
        if (mUser != null && mUser.contains(Constants.SYMBOL_COMPARE_JID))
        {
            mUser = mUser.split(Constants.SYMBOL_COMPARE_JID)[0];
        }
        
        if (!from.equals(mUser)) {
            //Bundle up the intent and send the broadcast.
            Intent intent = new Intent(Constants.RECEIVE_MESSAGE);
            intent.setPackage(mApplicationContext.getPackageName());
            intent.putExtra(Constants.BUNDLE_FROM_JID, from);
            intent.putExtra(Constants.BUNDLE_MESSAGE_BODY, body);
            intent.putExtra(Constants.BUNDLE_MESSAGE_PARAMS, msgId);
            intent.putExtra(Constants.BUNDLE_MESSAGE_TYPE, message.getType().toString());
            intent.putExtra(Constants.BUNDLE_MESSAGE_SENDER_JID, from);
            intent.putExtra(Constants.MEDIA_URL, mediaURL);
            intent.putExtra(Constants.CUSTOM_TEXT, customText);
            intent.putExtra(Constants.META_TEXT, META_TEXT);
            intent.putExtra(Constants.time, time);
            intent.putExtra(Constants.DELAY_TIME, delayTime);
            intent.putExtra(Constants.STATUS_CODE, statusCode);
            intent.putExtra(Constants.SUBJECT, subject);
            if (chatState != null) {
                intent.putExtra(Constants.CHATSTATE_TYPE, chatState.toString().toLowerCase());
            }

            mApplicationContext.sendBroadcast(intent);
        }
    }

    private static Message parseEventStanzaMessage(Message message) {
        try {
            EventElement eventElement = message.getExtension(Constants.event, Constants.eventPubSubNameSpace);
            if (eventElement != null) {
                List<ExtensionElement> itemExtensions = eventElement.getExtensions();
                for (int i = 0; i < itemExtensions.size(); i++) {
                    ItemsExtension itemsExtension = (ItemsExtension) itemExtensions.get(i);
                    List<?> items = itemsExtension.getItems();
                    for (int j = 0; j < items.size(); j++) {
                        PayloadItem<?> it = (PayloadItem<?>) items.get(j);
                        SimplePayload payloadElement = (SimplePayload) it.getPayload();

                        String xmlStanza = (String) payloadElement.toXML();

                        message = (Message) PacketParserUtils.parseStanza(xmlStanza);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return message;
    }

    public static void sendBroadcast() {

    }

    public static void broadcastSuccessMessageToFlutter(Context mApplicationContext, SuccessState successState, String jid) {

        //Bundle up the intent and send the broadcast.
        Intent intent = new Intent(Constants.SUCCESS_MESSAGE);
        intent.setPackage(mApplicationContext.getPackageName());
        intent.putExtra(Constants.BUNDLE_SUCCESS_TYPE, successState.toString());
        intent.putExtra(Constants.FROM, jid);
        mApplicationContext.sendBroadcast(intent);
    }

    public static void broadcastErrorMessageToFlutter(Context mApplicationContext, ErrorState errorState, String exception, String jid) {

        Intent intent = new Intent(Constants.ERROR_MESSAGE);
        intent.setPackage(mApplicationContext.getPackageName());
        intent.putExtra(Constants.FROM, jid);
        intent.putExtra(Constants.BUNDLE_EXCEPTION, exception);
        intent.putExtra(Constants.BUNDLE_ERROR_TYPE, errorState.toString());
        mApplicationContext.sendBroadcast(intent);
    }

    public static void broadcastConnectionMessageToFlutter(Context mApplicationContext, ConnectionState connectionState, String errorMessage) {

        Intent intent = new Intent(Constants.CONNECTION_STATE_MESSAGE);
        intent.setPackage(mApplicationContext.getPackageName());
        intent.putExtra(Constants.BUNDLE_CONNECTION_TYPE, connectionState.toString());
        intent.putExtra(Constants.BUNDLE_CONNECTION_ERROR, errorMessage);
        mApplicationContext.sendBroadcast(intent);
    }

    public static List<String> extractUrlsFromMessage(Message message) {
        List<String> urls = new ArrayList<String>();
        String xml = message.toXML().toString();
        String startTag = "<url";
        String endTag = "</url>";
        int currentIndex = 0;

        while (true) {
            int start = xml.indexOf(startTag, currentIndex);
            if (start == -1) break;

            int startClose = xml.indexOf(">", start);
            int end = xml.indexOf(endTag, startClose);
            if (startClose != -1 && end != -1 && startClose < end) {
                String url = xml.substring(startClose + 1, end).trim();
                if (!url.isEmpty()) {
                    urls.add(url);
                    Utils.printLog("Found URL: " + url);
                }
                currentIndex = end + endTag.length(); // Move past this tag
            } else {
                break; // Invalid tag structure
            }
        }

        return urls;
    }

    public static String extractStatusCode(Message message) {
        String xml = message.toXML().toString();
        String startTag = "<status code='";
        
        int start = xml.indexOf(startTag);
        
        if (start != -1) {
            int startClose = xml.indexOf("'", start);
            if (startClose != -1) {
                String code = xml.substring(startClose + 1, startClose + 5).trim();
                Utils.printLog("Found status code: " + code);
                return code;
            }
        }

        return "";
    }

    public static String extractSubject(Message message) {
        String xml = message.toXML().toString();
        String startTag = "<subject>";
        String endTag = "</subject>";
        
        int start = xml.indexOf(startTag);
        int end = xml.indexOf(endTag);
        
        if (start != -1 && end != -1) {
            int startClose = xml.indexOf(">", start);
            if (startClose != -1 && startClose < end) {
                String subject = xml.substring(startClose + 1, end).trim();
                Utils.printLog("Found subject: " + subject);
                return subject;
            }
        }

        return null;
    }
}
