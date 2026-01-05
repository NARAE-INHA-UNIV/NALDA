



// *** 테스트 과정에서 작성했던 비디오 "재송출" 코드이므로 카메라 수령 후엔 단순 송출 기능으로 변환하여 서버를 구축하면 됨. 


#include <gst/gst.h>
#include <gst/rtsp-server/rtsp-server.h>

static void client_connected_handler(GstRTSPServer *server, GstRTSPClient *client) {
    g_print("\n*** client PC (GCS) is conntected to me! ***\n");
}


int main(int argc, char *argv[]) {
    GMainLoop *loop;
    GstRTSPServer *server;
    GstRTSPMountPoints *mounts;
    GstRTSPMediaFactory *factory;

    gst_init(&argc, &argv);
    loop = g_main_loop_new(NULL, FALSE);
    server = gst_rtsp_server_new();

    //클라이언트 (맥pc)에서 우분투 서버에 접속했는지 확인하기위한 콜백함수 등록    g_signal_connect(server, "client-connected", (GCallback)client_connected_handler, NULL);
    g_object_set(server, "service", "8554", NULL);
    mounts = gst_rtsp_server_get_mount_points(server);

    factory = gst_rtsp_media_factory_new();

    // rtspsrc를 사용하여 IP 카메라 앱의 스트림을 받기
    // location 주소는 실제 스마트폰 앱에 표시된 주소로 변경함
    // gst_rtsp_media_factory_set_launch(factory,
    //     "( rtspsrc location=rtsp://192.168.48.25:8080/h264_ulaw.sdp latency=0 ! rtph264pay name=pay0 pt=96 )");

    // [수정된 파이프라인]
    // 안드로이드폰 영상을 디코딩한 후, 표준 x264로 다시 인코딩하여 호환성을 높임 
    // TODO -> 테스트 결과 실패(Qt앱 FFmpeg 오류, ReadMe 참고) / 카메라 준비 완료 후 파이프라인 재구성 필요 
    gst_rtsp_media_factory_set_launch(factory,
        "( rtspsrc location=rtsp://172.30.1.41:8080/h264_ulaw.sdp latency=0 ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! x264enc tune=zerolatency ! rtph264pay name=pay0 pt=96 )");

    gst_rtsp_mount_points_add_factory(mounts, "/phone_stream", factory);
    g_object_unref(mounts);
    gst_rtsp_server_attach(server, NULL);

    g_print("RTSP server is running on:\n");
    g_print(" - android camera: rtsp://<VM\uc758 IP>:8554/phone_stream\n");

    g_main_loop_run(loop);

    return 0;
}


// 단순 송출 코드 
// #include <gst/gst.h>

// int main(int argc, char *argv[]) {
//     GstElement *pipeline;
//     GstBus *bus;
//     GstMessage *msg;
//     GError *error = NULL;

//     // 1. GStreamer \ucd08\uae30\ud654
//     gst_init(&argc, &argv);

// 2. 재생용 파이프라인 생성
// 안드로이드폰에 접속(rtspsrc)하여 해석（depay,decode）후，
// 화면에 창을 띄워(autovideosink) 보여주는 파이프라인
// location 주소는 실제 스마트폰 앱에 표시된 주소
//     pipeline = gst_parse_launch(
//         "rtspsrc location=rtsp://172.30.1.22:8080/h264_ulaw.sdp latency=0 ! rtph264depay ! avdec_h264 ! autovideosink",
//         &error);

//     if (error) {
//         g_printerr("Pipeline making fail: %s\n", error->message);
//         g_clear_error(&error);
//         return -1;
//     }


//     3. 파이프라인을 재생 상태로 변경
//     gst_element_set_state(pipeline, GST_STATE_PLAYING);
//     g_print("Pipeline is Running...\n");
//     g_print("Press Ctrl+C to quit.\n");

//     // 4. 메시지 버스를 통해 에러 또는 종료 신호를 기다림
//     bus = gst_element_get_bus(pipeline);
//     msg = gst_bus_timed_pop_filtered(bus, GST_CLOCK_TIME_NONE, GST_MESSAGE_ERROR | GST_MESSAGE_EOS);

//     // 5. 메시지 처리 
//     if (msg != NULL) {
//         if (GST_MESSAGE_TYPE(msg) == GST_MESSAGE_ERROR) {
//             gst_message_parse_error(msg, &error, NULL);
//             g_printerr("error: %s\n", error->message);
//             g_clear_error(&error);
//         }
//         gst_message_unref(msg);
//     }

//     // 6. 자원 해제 
//     gst_element_set_state(pipeline, GST_STATE_NULL);
//     gst_object_unref(pipeline);
//     gst_object_unref(bus);

//     return 0;
// }
